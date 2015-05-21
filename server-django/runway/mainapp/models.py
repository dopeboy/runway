from django.db import models
import uuid
from django.contrib.auth.models import AbstractUser
from django.conf import settings


class Photo(models.Model):
    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4,
                            editable=False)
    url = models.CharField(max_length=256)
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='photos')
    created = models.DateTimeField(auto_now_add=True)


class MyUser(AbstractUser):
    GENDER_CHOICES = (
        ('M', 'Male'),
        ('F', 'Female')
    )

    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4,
                            editable=False)
    # One user can have multiple favorite photos; one photo can be favorited
    # by multiple users
    favorite_photos = models.ManyToManyField(Photo)
    gender = models.CharField(max_length=1, choices=GENDER_CHOICES)
    fb_userid = models.CharField(max_length=32)
    USERNAME_FIELD = 'username'


class ClothingType(models.Model):
    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4,
                            editable=False)
    label = models.CharField(max_length=256)
    created = models.DateTimeField(auto_now_add=True)


class Brand(models.Model):
    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4,
                            editable=False)
    label = models.CharField(max_length=256)
    created = models.DateTimeField(auto_now_add=True)


class Tag(models.Model):
    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4,
                            editable=False)
    photo_uuid = models.ForeignKey(Photo)
    point_x = models.DecimalField(max_digits=10, decimal_places=3)
    point_y = models.DecimalField(max_digits=10, decimal_places=3)
    clothing_type_uuid = models.ForeignKey(ClothingType)
    brand_uuid = models.ForeignKey(Brand)
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='tags')
    created = models.DateTimeField(auto_now_add=True)


class DownvoteReason(models.Model):
    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4,
                            editable=False)
    label = models.CharField(max_length=256)
    created = models.DateTimeField(auto_now_add=True)


class Vote(models.Model):
    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4,
                            editable=False)
    tag_uuid = models.ForeignKey(Tag)
    downvote_reason_uuid = models.ForeignKey(DownvoteReason)
    direction = models.IntegerField()  # 1 or -1
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='votes')
    created = models.DateTimeField(auto_now_add=True)
