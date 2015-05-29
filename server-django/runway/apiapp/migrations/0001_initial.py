# -*- coding: utf-8 -*-
from __future__ import unicode_literals

from django.db import models, migrations
import django.utils.timezone
import django.core.validators
import uuid
import django.contrib.auth.models
from django.conf import settings


class Migration(migrations.Migration):

    dependencies = [
        ('auth', '0006_require_contenttypes_0002'),
    ]

    operations = [
        migrations.CreateModel(
            name='MyUser',
            fields=[
                ('password', models.CharField(verbose_name='password', max_length=128)),
                ('last_login', models.DateTimeField(null=True, blank=True, verbose_name='last login')),
                ('is_superuser', models.BooleanField(help_text='Designates that this user has all permissions without explicitly assigning them.', verbose_name='superuser status', default=False)),
                ('username', models.CharField(error_messages={'unique': 'A user with that username already exists.'}, validators=[django.core.validators.RegexValidator('^[\\w.@+-]+$', 'Enter a valid username. This value may contain only letters, numbers and @/./+/-/_ characters.', 'invalid')], help_text='Required. 30 characters or fewer. Letters, digits and @/./+/-/_ only.', verbose_name='username', unique=True, max_length=30)),
                ('first_name', models.CharField(verbose_name='first name', blank=True, max_length=30)),
                ('last_name', models.CharField(verbose_name='last name', blank=True, max_length=30)),
                ('email', models.EmailField(verbose_name='email address', blank=True, max_length=254)),
                ('is_staff', models.BooleanField(help_text='Designates whether the user can log into this admin site.', verbose_name='staff status', default=False)),
                ('is_active', models.BooleanField(help_text='Designates whether this user should be treated as active. Unselect this instead of deleting accounts.', verbose_name='active', default=True)),
                ('date_joined', models.DateTimeField(verbose_name='date joined', default=django.utils.timezone.now)),
                ('uuid', models.UUIDField(primary_key=True, editable=False, serialize=False, default=uuid.uuid4)),
                ('gender', models.CharField(choices=[('M', 'Male'), ('F', 'Female')], max_length=1)),
                ('fb_userid', models.CharField(max_length=32)),
            ],
            options={
                'verbose_name': 'user',
                'verbose_name_plural': 'users',
                'abstract': False,
            },
            managers=[
                ('objects', django.contrib.auth.models.UserManager()),
            ],
        ),
        migrations.CreateModel(
            name='Brand',
            fields=[
                ('uuid', models.UUIDField(primary_key=True, editable=False, serialize=False, default=uuid.uuid4)),
                ('label', models.CharField(max_length=256)),
                ('created', models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.CreateModel(
            name='ClothingType',
            fields=[
                ('uuid', models.UUIDField(primary_key=True, editable=False, serialize=False, default=uuid.uuid4)),
                ('label', models.CharField(max_length=256)),
                ('created', models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.CreateModel(
            name='DownvoteReason',
            fields=[
                ('uuid', models.UUIDField(primary_key=True, editable=False, serialize=False, default=uuid.uuid4)),
                ('label', models.CharField(max_length=256)),
                ('created', models.DateTimeField(auto_now_add=True)),
            ],
        ),
        migrations.CreateModel(
            name='Photo',
            fields=[
                ('uuid', models.UUIDField(primary_key=True, editable=False, serialize=False, default=uuid.uuid4)),
                ('url', models.CharField(max_length=256)),
                ('created', models.DateTimeField(auto_now_add=True)),
                ('owner', models.ForeignKey(related_name='photos', to=settings.AUTH_USER_MODEL)),
            ],
        ),
        migrations.CreateModel(
            name='Tag',
            fields=[
                ('uuid', models.UUIDField(primary_key=True, editable=False, serialize=False, default=uuid.uuid4)),
                ('point_x', models.DecimalField(decimal_places=3, max_digits=10)),
                ('point_y', models.DecimalField(decimal_places=3, max_digits=10)),
                ('created', models.DateTimeField(auto_now_add=True)),
                ('brand_uuid', models.ForeignKey(to='apiapp.Brand')),
                ('clothing_type_uuid', models.ForeignKey(to='apiapp.ClothingType')),
                ('owner', models.ForeignKey(related_name='tags', to=settings.AUTH_USER_MODEL)),
                ('photo_uuid', models.ForeignKey(to='apiapp.Photo')),
            ],
        ),
        migrations.CreateModel(
            name='Vote',
            fields=[
                ('uuid', models.UUIDField(primary_key=True, editable=False, serialize=False, default=uuid.uuid4)),
                ('direction', models.IntegerField()),
                ('created', models.DateTimeField(auto_now_add=True)),
                ('downvote_reason_uuid', models.ForeignKey(to='apiapp.DownvoteReason')),
                ('owner', models.ForeignKey(related_name='votes', to=settings.AUTH_USER_MODEL)),
                ('tag_uuid', models.ForeignKey(to='apiapp.Tag')),
            ],
        ),
        migrations.AddField(
            model_name='myuser',
            name='favorite_photos',
            field=models.ManyToManyField(to='apiapp.Photo'),
        ),
        migrations.AddField(
            model_name='myuser',
            name='groups',
            field=models.ManyToManyField(related_name='user_set', to='auth.Group', help_text='The groups this user belongs to. A user will get all permissions granted to each of their groups.', verbose_name='groups', blank=True, related_query_name='user'),
        ),
        migrations.AddField(
            model_name='myuser',
            name='user_permissions',
            field=models.ManyToManyField(related_name='user_set', to='auth.Permission', help_text='Specific permissions for this user.', verbose_name='user permissions', blank=True, related_query_name='user'),
        ),
    ]
