from rest_framework import serializers
from mainapp.models import Photo, MyUser


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
        fields = ('uuid', 'username', 'photos')
