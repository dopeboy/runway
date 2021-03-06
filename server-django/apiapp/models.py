from django.db import models
from django.contrib.auth.models import BaseUserManager, AbstractBaseUser
import uuid
from django.conf import settings


class Photo(models.Model):
    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4,
                            editable=False)
    url = models.CharField(max_length=256)
    thumb_url = models.CharField(max_length=256)
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='photos')

    # viewers are users who have seen the photo
    viewers = models.ManyToManyField(settings.AUTH_USER_MODEL,
                                     through='PhotoViewership')

    created = models.DateTimeField(auto_now_add=True)


class PhotoViewership(models.Model):
    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4,
                            editable=False)
    user = models.ForeignKey(settings.AUTH_USER_MODEL)
    photo = models.ForeignKey(Photo)
    date_viewed = models.DateField(auto_now_add=True)


class MyUserManager(BaseUserManager):
    def create_user(self, email, gender, date_of_birth=None, password=None):
        """
        Creates and saves a User with the given email,
        gender and password.
        """
        if not email:
            raise ValueError('Users must have an email address')

        if not gender:
            raise ValueError('Users must have a gender')

        user = self.model(
            email=self.normalize_email(email),
            gender=gender,
            date_of_birth=date_of_birth
        )

        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, gender, password):
        """
        Creates and saves a superuser with the given email,
        gender and password.
        """
        user = self.create_user(email, gender, password=password)
        user.is_admin = True
        user.save(using=self._db)
        return user


class MyUser(AbstractBaseUser):
    first_name = models.CharField(max_length=32)
    last_name = models.CharField(max_length=32)

    email = models.EmailField(
        verbose_name='email address',
        max_length=255,
        unique=True,
    )

    date_of_birth = models.DateField(null=True)
    is_active = models.BooleanField(default=True)
    is_admin = models.BooleanField(default=False)

    # Is a seeded (fake) user
    is_seed = models.BooleanField(default=False)

    objects = MyUserManager()

    GENDER_CHOICES = (
        ('M', 'Male'),
        ('F', 'Female')
    )

    SOCIAL_CHOICES = (
        ('FB', 'Facebook'),
    )

    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4,
                            editable=False)

    gender = models.CharField(max_length=1, choices=GENDER_CHOICES)

    # This store the user ID from the service they used to log in.
    social_userid = models.CharField(max_length=64)

    # The service they used to log in
    social_source = models.CharField(max_length=4, choices=SOCIAL_CHOICES)

    # The profile picture on the service they used to login on
    social_profile_picture = models.CharField(max_length=320)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['gender']

    def get_full_name(self):
        # The user is identified by their email address
        return self.first_name + " " + self.last_name

    def get_short_name(self):
        # The user is identified by their email address
        return self.first_name

    def __str__(self):              # __unicode__ on Python 2
        return self.email

    def has_perm(self, perm, obj=None):
        "Does the user have a specific permission?"
        # Simplest possible answer: Yes, always
        return True

    def has_module_perms(self, app_label):
        "Does the user have permissions to view the app `app_label`?"
        # Simplest possible answer: Yes, always
        return True

    @property
    def is_staff(self):
        "Is the user a member of staff?"
        # Simplest possible answer: All admins are staff
        return self.is_admin


class ClothingType(models.Model):
    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4,
                            editable=False)
    label = models.CharField(max_length=256)
    created = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return str(self.uuid)


class Brand(models.Model):
    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4,
                            editable=False)
    name = models.CharField(max_length=256)
    created = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return str(self.uuid)


class Tag(models.Model):
    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4,
                            editable=False)
    photo = models.ForeignKey(Photo, related_name='tags')
    point_x = models.DecimalField(max_digits=10, decimal_places=3)
    point_y = models.DecimalField(max_digits=10, decimal_places=3)
    clothing_type = models.ForeignKey(ClothingType)
    brand = models.ForeignKey(Brand)
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
    tag = models.ForeignKey(Tag, related_name='votes')
    downvote_reason = models.ForeignKey(DownvoteReason, null=True)
    value = models.IntegerField()  # 1 or -1
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, related_name='votes')
    created = models.DateTimeField(auto_now_add=True)

    # For a given tag, the maximum number of votes a person can
    # cast for it is 1.
    class Meta:
        unique_together = ("tag", "owner")


class Invite(models.Model):
    uuid = models.UUIDField(primary_key=True, default=uuid.uuid4,
                            editable=False)
    code = models.CharField(blank=False, max_length=256)
    count = models.IntegerField(blank=False)
    created = models.DateTimeField(auto_now_add=True)
