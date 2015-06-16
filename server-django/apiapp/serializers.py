from rest_framework import serializers
from apiapp.models import Photo, MyUser
from django.contrib.auth import authenticate


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


class AuthTokenEmailSerializer(serializers.Serializer):
    email = serializers.EmailField(required=True)
    password = serializers.CharField(required=True)

    def validate(self, attrs):
        email = attrs.get('email')
        password = attrs.get('password')

        if email and password:
            user = authenticate(email=email, password=password)

            if user:
                if not user.is_active:
                    msg = 'User account is disabled.'
                    raise serializers.ValidationError(msg)
            # Sign up
            else:
                user = MyUser.objects.create_user(email=email,
                                                  gender='M',
                                                  password=password)
                # msg = 'Unable to log in with provided credentials.'
                # raise serializers.ValidationError(msg)

        else:
            msg = 'Must include "username" and "password"'
            raise serializers.ValidationError(msg)

        attrs['user'] = user
        return attrs
