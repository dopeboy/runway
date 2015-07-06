from rest_framework import serializers
from apiapp.models import Photo, MyUser, ClothingType, Brand, \
        Tag, Vote, DownvoteReason
from django.contrib.auth import authenticate
import requests
import json
from datetime import datetime
import logging
from django.core.exceptions import ObjectDoesNotExist
from django.db.models import Sum
from django.db.models.functions import Coalesce
from django.db import connection

logger = logging.getLogger(__name__)


class AuthTokenFacebookSerializer(serializers.Serializer):
    fb_access_token = serializers.CharField(required=True)

    def validate(self, attrs):
        fb_access_token = attrs.get('fb_access_token')

        if fb_access_token:
            # Get user profile information
            r = requests.get("https://graph.facebook.com/v2.3/me?" +
                             "access_token=" + fb_access_token +
                             "&fields=id,first_name,last_name," +
                             "birthday,gender,email")

            if r.status_code != 200:
                msg = 'Invalid facebook access token'
                raise serializers.ValidationError(msg)

            fb_response_profile_info = json.loads(r.content.decode('utf8'))

            # Get profile picture information
            r = requests.get("https://graph.facebook.com/v2.3/me/picture?" +
                             "redirect=false&width=320" +
                             "&access_token=" + fb_access_token)

            if r.status_code != 200:
                msg = 'Invalid facebook access token'
                raise serializers.ValidationError(msg)

            fb_response_profile_picture = json.loads(r.content.decode('utf8'))

            user = authenticate(email=fb_response_profile_info['email'],
                                password='lol')

            if user:
                if not user.is_active:
                    msg = 'User account is disabled.'
                    raise serializers.ValidationError(msg)

            # Sign up
            else:
                user = MyUser.objects.create_user(
                    email=fb_response_profile_info['email'],
                    gender=fb_response_profile_info['gender'][0].upper(),
                    password='lol')

                user.first_name = fb_response_profile_info['first_name']
                user.last_name = fb_response_profile_info['last_name']
                user.social_source = 'FB'
                user.social_userid = fb_response_profile_info['id']
                user.social_profile_picture = \
                    fb_response_profile_picture['data']['url']
                user.date_of_birth = \
                    datetime.strptime(fb_response_profile_info['birthday'],
                                      '%m/%d/%Y')
                user.save()

        else:
            msg = 'No facebook access token supplied'
            raise serializers.ValidationError(msg)

        attrs['user'] = user
        return attrs


class FacebookFriendSerializer(serializers.Serializer):
    fb_access_token = serializers.CharField(required=True)

    def validate(self, attrs):
        fb_access_token = attrs.get('fb_access_token')
        attrs['fb_friends'] = []

        if fb_access_token:
            r = requests.get("https://graph.facebook.com/v2.3/me/friends?" +
                             "access_token=" + fb_access_token)

            if r.status_code != 200:
                msg = 'Invalid facebook access token'
                raise serializers.ValidationError(msg)

            fb_friends = json.loads(r.content.decode('utf8'))

            # For each friend, look them up by FB user ID and
            # save their user object.
            # TODO - flatten fb_friends and use an IN clause
            # and also sort by karma descending
            for friend in fb_friends['data']:
                try:
                    u = MyUser.objects.get(social_userid=friend['id'])
                    attrs['fb_friends'].append(u)
                except:
                    pass

        else:
            msg = 'No facebook access token supplied'
            raise serializers.ValidationError(msg)

        return attrs


class ClothingTypeSerializer(serializers.ModelSerializer):
    clothing_type_uuid = serializers.UUIDField(source='uuid')
    clothing_type_label = serializers.CharField(source='label')

    class Meta:
        model = ClothingType
        fields = ('clothing_type_uuid', 'clothing_type_label')


class BrandTypeSerializer(serializers.ModelSerializer):
    brand_uuid = serializers.UUIDField(source='uuid')
    brand_name = serializers.CharField(source='name')

    class Meta:
        model = Brand
        fields = ('brand_uuid', 'brand_name')


class DownvoteReasonSerializer(serializers.ModelSerializer):
    downvotereason_uuid = serializers.UUIDField(source='uuid')
    downvotereason_label = serializers.CharField(source='label')

    class Meta:
        model = DownvoteReason
        fields = ('downvotereason_uuid', 'downvotereason_label')


class TagSerializer(serializers.ModelSerializer):
    # Required is false here because it is unknown when
    # tags are created along an image.
    img_uuid = serializers.UUIDField(required=False, write_only=True,
                                     source='photo')
    tag_uuid = serializers.UUIDField(read_only=True, source='uuid')
    clothing_type_uuid = serializers.UUIDField(read_only=False,
                                               source='clothing_type')
    clothing_type_label = serializers.SerializerMethodField(read_only=True)
    brand_uuid = serializers.UUIDField(read_only=False, source='brand')
    brand_name = serializers.SerializerMethodField(read_only=True)

    karma = serializers.SerializerMethodField()
    upvote_total = serializers.SerializerMethodField()
    downvote_total = serializers.SerializerMethodField()
    my_vote = serializers.SerializerMethodField()
    downvotereason_summary = serializers.SerializerMethodField()

    class Meta:
        model = Tag
        fields = ('tag_uuid', 'point_x', 'point_y',
                  'clothing_type_uuid', 'clothing_type_label', 'brand_uuid',
                  'brand_name', 'img_uuid', 'upvote_total', 'downvote_total',
                  'downvotereason_summary', 'karma', 'my_vote')

    # For some reason, if I use the img_uuid field above,
    # it doesn't validate and spits the UUID out.
    # This validates the UUID and returns the photo object
    # attached to it.
    def validate_img_uuid(self, data):
        try:
            p = Photo.objects.get(pk=data)
        except ObjectDoesNotExist:
            raise serializers.ValidationError('This photo does not exist')

        return p

    def validate_clothing_type_uuid(self, data):
        try:
            c = ClothingType.objects.get(pk=data)
        except ObjectDoesNotExist:
            raise serializers.ValidationError('This clothing type \
                    does not exist')

        return c

    def validate_brand_uuid(self, data):
        try:
            b = Brand.objects.get(pk=data)
        except ObjectDoesNotExist:
            raise serializers.ValidationError('This brand does not exist')

        return b

    def get_clothing_type_label(self, tag):
        return tag.clothing_type.label

    def get_brand_name(self, tag):
        return tag.brand.name

    def get_karma(self, tag):
        return tag.votes.all().aggregate(sum=Coalesce(Sum('value'), 0))['sum']

    def get_upvote_total(self, tag):
        return tag.votes.all().filter(value=1).aggregate(
                sum=Coalesce(Sum('value'), 0))['sum']

    def get_downvote_total(self, tag):
        return tag.votes.all().filter(value=-1).aggregate(
                sum=Coalesce(Sum('value'), 0))['sum']

    # Custom SQL for now because couldn't figure out
    # how to use the ORM for it.
    # TODO - convert to ORM
    def get_downvotereason_summary(self, tag):
        def dictfetchall(cursor):
            "Returns all rows from a cursor as a dict"
            desc = cursor.description
            return [
                dict(zip([col[0] for col in desc], row))
                for row in cursor.fetchall()
            ]

        cursor = connection.cursor()
        cursor.execute('''SELECT
        CAST("apiapp_downvotereason"."uuid" as varchar(32))
        as "downvotereason_uuid",
        "apiapp_downvotereason"."label" as "downvotereason_label",
        COUNT("apiapp_vote"."uuid") AS "count",
        COALESCE(COUNT("apiapp_vote"."uuid")/SUM("apiapp_vote"."value")
        * 100,0) as "percentage"
        FROM "apiapp_downvotereason"
        LEFT OUTER JOIN "apiapp_vote" ON ( "apiapp_downvotereason"."uuid" =
        "apiapp_vote"."downvote_reason_id" AND "apiapp_vote"."tag_id" = %s
        AND "apiapp_vote"."value" = -1)
        GROUP BY "apiapp_downvotereason"."uuid"
        ORDER BY "percentage" DESC''', [tag.uuid])

        return dictfetchall(cursor)

    def get_my_vote(self, tag):
        value = None
        try:
            value = tag.votes.all().get(
                    owner=self.context['request'].user).value
        except ObjectDoesNotExist:
            value = 0

        return value


class PhotoSerializer(serializers.ModelSerializer):
    tags = TagSerializer(many=True)
    img_url = serializers.CharField(max_length=256, source='url')
    thumb_img_url = serializers.CharField(max_length=256, source='thumb_url')

    # Read only is true here because we only want it when reading,
    # don't care on writing or updating
    img_uuid = serializers.UUIDField(read_only=True, source='uuid')

    # For this photo, get all the associated tags.
    # For each tag, find the associated votes.
    # For each vote, sum the values
    karma = serializers.SerializerMethodField()

    # Description of each photo
    description = serializers.SerializerMethodField()

    class Meta:
        model = Photo
        fields = ('img_uuid', 'tags', 'img_url', 'karma', 'description',
                  'thumb_img_url')

    def create(self, validated_data):
        tags = validated_data.pop('tags')
        photo = Photo.objects.create(**validated_data)
        for tag in tags:
            Tag.objects.create(photo=photo,
                               owner=validated_data['owner'], **tag)
        return photo

    def get_karma(self, photo):
        return photo.tags.all().aggregate(
            sum=Coalesce(Sum('votes__value'), 0))['sum']
#        karma = 0
#        for tag in photo.tags.all():
#            for vote in tag.votes.all():
#                karma += vote.value
#
#        return karma

    # TODO - fix
    def get_description(self, photo):
        return "placeholder"


class UserSerializer(serializers.ModelSerializer):
    user_uuid = serializers.UUIDField(read_only=True, source='uuid')
    user_img_url = serializers.CharField(read_only=True,
                                         source='social_profile_picture')
    karma = serializers.SerializerMethodField()

    # Description of each user
    description = serializers.SerializerMethodField()

    class Meta:
        model = MyUser
        fields = ('user_uuid', 'user_img_url', 'description', 'karma')

    # TODO - fix
    def get_description(self, user):
        return "placeholder"

    def get_karma(self, user):
        return user.photos.all().aggregate(
            sum=Coalesce(Sum('tags__votes__value'), 0))['sum']


class VoteSerializer(serializers.ModelSerializer):
    tag_uuid = serializers.UUIDField(read_only=False, source='tag')
    downvote_reason_uuid = serializers.UUIDField(read_only=False,
                                                 source='downvote_reason')

    class Meta:
        model = Vote
        fields = ('tag_uuid', 'value', 'downvote_reason_uuid')

    def validate_tag_uuid(self, data):
        try:
            t = Tag.objects.get(pk=data)
        except ObjectDoesNotExist:
            raise serializers.ValidationError('This tag does not exist')

        return t

    def validate_downvote_reason_uuid(self, data):
        try:
            d = DownvoteReason.objects.get(pk=data)
        except ObjectDoesNotExist:
            raise serializers.ValidationError('This downvote reason \
                    does not exist')

        return d
