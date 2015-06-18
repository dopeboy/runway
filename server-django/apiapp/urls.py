from django.conf.urls import url, include
from apiapp import views
from rest_framework.routers import DefaultRouter

uuid_pattern = ('[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-'
                '[a-f0-9]{12}')

# Create a router and register our viewsets with it.
router = DefaultRouter()
router.register(r'photos', views.PhotoViewSet)
router.register(r'users', views.UserViewSet)
router.register(r'clothingtypes', views.ClothingTypeViewSet)
router.register(r'brands', views.BrandViewSet)

urlpatterns = [
    url(r'^', include(router.urls)),
    url(r'^api-auth/', include('rest_framework.urls',
                               namespace='rest_framework')),
    url(r'^login/', 'apiapp.views.obtain_expiring_auth_token')
]
