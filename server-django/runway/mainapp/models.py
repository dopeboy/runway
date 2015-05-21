from django.db import models
import uuid
from django.contrib.auth.models import AbstractUser
from django.conf import settings


class Photo(models.Model):
    created = models.DateTimeField(auto_now_add=True)
    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4,
                            editable=False)
    url = models.CharField(max_length=256)
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='photos')


class MyUser(AbstractUser):
    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4,
                            editable=False)
    USERNAME_FIELD = 'username'
