from django.conf.urls import url, include
from apiapp import views
from rest_framework.routers import DefaultRouter

uuid_pattern = ('[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-'
                '[a-f0-9]{12}')

# Create a router and register our viewsets with it.
router = DefaultRouter()
router.register(r'photos', views.PhotoViewSet, 'Photo')
router.register(r'users', views.UserViewSet)
router.register(r'clothingtypes', views.ClothingTypeViewSet)
router.register(r'downvotereasons', views.DownvoteViewSet)
router.register(r'brands', views.BrandViewSet)
router.register(r'tags', views.TagViewSet)
router.register(r'votes', views.VoteViewSet)

urlpatterns = [
    url(r'^photos/next/$', 'apiapp.views.generate_next_photo'),
    url(r'^photos/favorites/$', 'apiapp.views.get_favorite_photos'),
    url(r'^users/leaderboard/$', 'apiapp.views.get_leaderboard_users'),
    url(r'^', include(router.urls)),
    url(r'^api-auth/', include('rest_framework.urls',
                               namespace='rest_framework')),
    url(r'^login/', 'apiapp.views.obtain_expiring_auth_token')
]
