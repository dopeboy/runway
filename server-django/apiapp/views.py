from apiapp.models import Photo, MyUser,\
        ClothingType, Brand, Tag, Vote, DownvoteReason
from apiapp.serializers import PhotoSerializer, UserSerializer, \
        AuthTokenFacebookSerializer, ClothingTypeSerializer, \
        BrandTypeSerializer, TagSerializer, VoteSerializer, \
        DownvoteReasonSerializer, FacebookFriendSerializer
from rest_framework import permissions
from apiapp.permissions import IsOwnerOrReadOnly
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework.reverse import reverse
from rest_framework import viewsets
from django.conf import settings
from rest_framework.authtoken.views import ObtainAuthToken
from rest_framework.authtoken.models import Token
import datetime
from django.http import HttpResponse
import json
from rest_framework import status
import pytz
from rest_framework.authentication \
        import SessionAuthentication, BasicAuthentication
from apiapp.authentication import ExpiringTokenAuthentication
from rest_framework.permissions import IsAuthenticated
from rest_framework.decorators \
        import permission_classes, authentication_classes
import logging
from rest_framework.views import APIView
import random
from django.db.models import Sum
from django.db.models.functions import Coalesce

EXPIRE_HOURS = getattr(settings, 'REST_FRAMEWORK_TOKEN_EXPIRE_HOURS')
logger = logging.getLogger(__name__)


@api_view(('GET',))
@authentication_classes((SessionAuthentication, BasicAuthentication,
                        ExpiringTokenAuthentication))
@permission_classes((IsAuthenticated,))
def api_root(request, format=None):
    return Response({
        'users': reverse('user-list', request=request, format=format),
        'photos': reverse('photo-list', request=request, format=format)
    })


class PhotoViewSet(viewsets.ModelViewSet):
    """
    This viewset automatically provides `list`, `create`, `retrieve`,
    `update` and `destroy` actions.

    """
    authentication_classes = (SessionAuthentication,
                              BasicAuthentication,
                              ExpiringTokenAuthentication)
    serializer_class = PhotoSerializer
    permission_classes = (IsAuthenticated, IsOwnerOrReadOnly)
    queryset = Photo.objects.all()

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)

    def list(self, request):
        me = request.user
        queryset = Photo.objects.filter(owner=self.request.user)
        serializer = PhotoSerializer(queryset, many=True,
                                     context={'request': self.request})
        response_data = {'images': serializer.data}

        return HttpResponse(json.dumps(addUserKarma(response_data, me)),
                            content_type="application/json")


class UserViewSet(viewsets.ReadOnlyModelViewSet):
    """
    This viewset automatically provides `list` and `detail` actions.
    """
    authentication_classes = (SessionAuthentication,
                              BasicAuthentication,
                              ExpiringTokenAuthentication)
    permission_classes = (IsAuthenticated,)
    queryset = MyUser.objects.all()
    serializer_class = UserSerializer


class GenerateNextPhoto(APIView):
    serializer_class = PhotoSerializer
    authentication_classes = (SessionAuthentication,
                              BasicAuthentication,
                              ExpiringTokenAuthentication)
    permission_classes = (IsAuthenticated,)

    def get(self, request, format=None):
        me = request.user

        # Find all the photos that I haven't seen and that I haven't made
        # photos = Photo.objects.all().exclude(
        #         uuid__in=me.photo_set.all().values_list(
        #             'uuid', flat=True)).exclude(owner=me)
        photos = Photo.objects.all()

        # If there are no photos left, return a dummy
        # photo (note this doesn't get saved)
        if len(photos) == 0:
            p = Photo(url='ohsnapnomorephotos.jpg', owner=me)

        else:
            # Randomly pick a photo
            p = random.choice(photos)

            # Mark it as viewed
            # me.photo_set.add(p)

        serializer = self.serializer_class(p,
                                           context={'request': self.request})
        response_data = {'image': serializer.data}

        return HttpResponse(json.dumps(addUserKarma(response_data, me)),
                            content_type="application/json")

generate_next_photo = GenerateNextPhoto.as_view()


# This will add the user's karma to the serialized data
def addUserKarma(serializedData, user):
    serializedData["user_karma"] = user.photos.all().aggregate(
            sum=Coalesce(Sum('tags__votes__value'), 0))['sum']
    return serializedData


# Return two lists: facebook friends and others
class GetLeaderboardUsers(APIView):
    serializer_class = UserSerializer
    authentication_classes = (SessionAuthentication,
                              BasicAuthentication,
                              ExpiringTokenAuthentication)
    permission_classes = (IsAuthenticated,)

    def post(self, request, format=None):
        me = request.user

        # Facebook list. Get my friends on the app
        serializer = FacebookFriendSerializer(data=request.DATA)

        if serializer.is_valid(raise_exception=True):
            fb_user_serializer = self.serializer_class(
                serializer.validated_data['fb_friends'],
                many=True, context={'request': self.request})

            # Now get non-FB friends. We'll need to pull the UUIDs
            # of the fb friends and exclude those from the list
            exclude_user_uuids = [me.uuid]

            for user in serializer.validated_data['fb_friends']:
                exclude_user_uuids.append(user.uuid)
            others = MyUser.objects.all().exclude(uuid__in=exclude_user_uuids)
            other_user_serializer = self.serializer_class(others, many=True)

            response_data = {'friends': fb_user_serializer.data,
                             'others': other_user_serializer.data}

            return HttpResponse(json.dumps(addUserKarma(response_data, me)),
                                content_type="application/json")

get_leaderboard_users = GetLeaderboardUsers.as_view()


# Find all photos that the user has upvoted atleast one thing on
# Sort by last upvoted
class GetFavoritePhotos(APIView):
    serializer_class = PhotoSerializer
    authentication_classes = (SessionAuthentication,
                              BasicAuthentication,
                              ExpiringTokenAuthentication)
    permission_classes = (IsAuthenticated,)

    def get(self, request, format=None):
        me = request.user

        photos = Photo.objects.filter(
                tags__votes__owner=me).order_by('-tags__votes__created')
        serializer = self.serializer_class(
                photos, many=True, context={'request': self.request})

        response_data = {'images': serializer.data}

        return HttpResponse(json.dumps(addUserKarma(response_data, me)),
                            content_type="application/json")

get_favorite_photos = GetFavoritePhotos.as_view()


class ObtainExpiringAuthToken(ObtainAuthToken):
    serializer_class = AuthTokenFacebookSerializer

    def post(self, request):
        serializer = self.serializer_class(data=request.DATA)
        if serializer.is_valid(raise_exception=True):
            user = serializer.validated_data['user']
            token, created = Token.objects.get_or_create(
                            user=user)

            utc_now = datetime.datetime.utcnow()
            utc_now = utc_now.replace(tzinfo=pytz.utc)

            if not created and \
                    token.created < \
                    utc_now - datetime.timedelta(hours=EXPIRE_HOURS):
                token.delete()
                token = Token.objects.create(user=user)
                token.created = datetime.datetime.utcnow()
                token.save()

            ct_queryset = ClothingType.objects.all().order_by('-label')
            ct_serializer = ClothingTypeSerializer(
                    ct_queryset, many=True, context={'request': self.request})

            b_queryset = Brand.objects.order_by('-name')
            b_serializer = BrandTypeSerializer(
                    b_queryset, many=True, context={'request': self.request})

            dvr_queryset = DownvoteReason.objects.all().order_by('-label')
            dvr_serializer = DownvoteReasonSerializer(
                    dvr_queryset, many=True, context={'request': self.request})

            response_data = {'access_token': token.key,
                             'clothing_types': ct_serializer.data,
                             'brands': b_serializer.data,
                             'downvote_reasons': dvr_serializer.data}
            response_data = addUserKarma(response_data, user)

            return HttpResponse(json.dumps(response_data),
                                content_type="application/json")

        return HttpResponse(json.dumps(serializer.errors),
                            content_type="application/json",
                            status=status.HTTP_400_BAD_REQUEST)

obtain_expiring_auth_token = ObtainExpiringAuthToken.as_view()


class ClothingTypeViewSet(viewsets.ReadOnlyModelViewSet):
    """
    This viewset automatically provides `list` and `detail` actions.
    """
    authentication_classes = (SessionAuthentication,
                              BasicAuthentication,
                              ExpiringTokenAuthentication)
    permission_classes = (IsAuthenticated,)
    queryset = ClothingType.objects.all().order_by('label')
    serializer_class = ClothingTypeSerializer


class BrandViewSet(viewsets.ReadOnlyModelViewSet):
    """
    This viewset automatically provides `list` and `detail` actions.
    """
    authentication_classes = (SessionAuthentication,
                              BasicAuthentication,
                              ExpiringTokenAuthentication)
    permission_classes = (IsAuthenticated,)
    queryset = Brand.objects.all().order_by('name')
    serializer_class = BrandTypeSerializer


class DownvoteViewSet(viewsets.ReadOnlyModelViewSet):
    """
    This viewset automatically provides `list` and `detail` actions.
    """
    authentication_classes = (SessionAuthentication,
                              BasicAuthentication,
                              ExpiringTokenAuthentication)
    permission_classes = (IsAuthenticated,)
    queryset = DownvoteReason.objects.all().order_by('label')
    serializer_class = DownvoteReasonSerializer


class TagViewSet(viewsets.ModelViewSet):
    """
    This viewset automatically provides `list`, `create`, `retrieve`,
    `update` and `destroy` actions.

    """
    authentication_classes = (SessionAuthentication,
                              BasicAuthentication,
                              ExpiringTokenAuthentication)
    permission_classes = (IsAuthenticated, IsOwnerOrReadOnly)
    queryset = Tag.objects.all()
    serializer_class = TagSerializer

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class VoteViewSet(viewsets.ModelViewSet):
    """
    This viewset automatically provides `list`, `create`, `retrieve`,
    `update` and `destroy` actions.

    """
    authentication_classes = (SessionAuthentication,
                              BasicAuthentication,
                              ExpiringTokenAuthentication)
    permission_classes = (permissions.IsAuthenticatedOrReadOnly,
                          IsOwnerOrReadOnly,)
    queryset = Vote.objects.all()
    serializer_class = VoteSerializer

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)
