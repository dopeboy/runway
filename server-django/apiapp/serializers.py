from rest_framework import serializers
from apiapp.models import Photo, MyUser, ClothingType, Brand
from django.contrib.auth import authenticate
import requests
import json
from datetime import datetime


class PhotoSerializer(serializers.ModelSerializer):
    class Meta:
        model = Photo
        fields = ('uuid', 'url', 'created')
        owner = serializers.ReadOnlyField(source='owner.username')


class UserSerializer(serializers.ModelSerializer):
    photos = serializers.HyperlinkedRelatedField(many=True,
                                                 view_name="photo-detail",
                                                 read_only=True)

    class Meta:
        model = MyUser
        fields = ('uuid', 'email', 'photos')


class AuthTokenFacebookSerializer(serializers.Serializer):
    fb_access_token = serializers.CharField(required=True)

    def validate(self, attrs):
        fb_access_token = attrs.get('fb_access_token')

        if fb_access_token:
            r = requests.get("https://graph.facebook.com/v2.3/me?" +
                             "access_token=" + fb_access_token +
                             "&fields=id,first_name,last_name," +
                             "birthday,gender,email")

            if r.status_code != 200:
                msg = 'Invalid facebook access token'
                raise serializers.ValidationError(msg)

            fb_response = json.loads(r.content.decode('utf8'))
            user = authenticate(email=fb_response['email'], password='lol')

            if user:
                if not user.is_active:
                    msg = 'User account is disabled.'
                    raise serializers.ValidationError(msg)

            # Sign up
            else:
                user = MyUser.objects.create_user(
                    email=fb_response['email'],
                    gender=fb_response['gender'][0].upper(),
                    password='lol')

                user.first_name = fb_response['first_name']
                user.last_name = fb_response['last_name']
                user.social_source = 'FB'
                user.social_userid = fb_response['id']
                user.date_of_birth = datetime.strptime(fb_response['birthday'],
                                                       '%m/%d/%Y')
                user.save()

        else:
            msg = 'Must include "username" and "password"'
            raise serializers.ValidationError(msg)

        attrs['user'] = user
        return attrs


class ClothingTypeSerializer(serializers.ModelSerializer):
    clothing_type_guid = serializers.UUIDField(source='uuid')
    clothing_type_label = serializers.CharField(source='label')

    class Meta:
        model = ClothingType
        fields = ('clothing_type_guid', 'clothing_type_label')


class BrandTypeSerializer(serializers.ModelSerializer):
    brand_guid = serializers.UUIDField(source='uuid')
    brand_nm = serializers.CharField(source='label')

    class Meta:
        model = Brand
        fields = ('brand_guid', 'brand_nm')
