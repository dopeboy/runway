from apiapp.models import Photo, MyUser
from apiapp.serializers import PhotoSerializer, UserSerializer, \
        AuthTokenEmailSerializer
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

EXPIRE_HOURS = getattr(settings, 'REST_FRAMEWORK_TOKEN_EXPIRE_HOURS')


@api_view(('GET',))
def api_root(request, format=None):
    return Response({
        'users': reverse('user-list', request=request, format=format),
        'photos': reverse('photo-list', request=request, format=format)
    })


class PhotoViewSet(viewsets.ModelViewSet):
    """
    This viewset automatically provides `list`, `create`, `retrieve`,
    `update` and `destroy` actions.

    Additionally we also provide an extra `highlight` action.
    """
    queryset = Photo.objects.all()
    serializer_class = PhotoSerializer
    permission_classes = (permissions.IsAuthenticatedOrReadOnly,
                          IsOwnerOrReadOnly,)

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class UserViewSet(viewsets.ReadOnlyModelViewSet):
    """
    This viewset automatically provides `list` and `detail` actions.
    """
    queryset = MyUser.objects.all()
    serializer_class = UserSerializer


class ObtainExpiringAuthToken(ObtainAuthToken):
    serializer_class = AuthTokenEmailSerializer

    def post(self, request):
        serializer = self.serializer_class(data=request.DATA)
        if serializer.is_valid():
            user = serializer.validated_data['user']
            token, created = Token.objects.get_or_create(
                            user=user)

            utc_now = datetime.datetime.utcnow()
            utc_now = utc_now.replace(tzinfo=pytz.utc)

            if not created and \
                    token.created < \
                    utc_now - datetime.timedelta(hours=EXPIRE_HOURS):
                token.delete()
                token = Token.objects.create(user=serializer.object['user'])
                token.created = datetime.datetime.utcnow()
                token.save()

            response_data = {'token': token.key}
            return HttpResponse(json.dumps(response_data),
                                content_type="application/json")

        return HttpResponse(serializer.errors,
                            status=status.HTTP_400_BAD_REQUEST)

obtain_expiring_auth_token = ObtainExpiringAuthToken.as_view()
