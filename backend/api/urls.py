from django.urls import path
from . import views

urlpatterns = [
    # Auth
    path("auth/register/", views.register_view, name="register"),
    path("auth/login/", views.login_view, name="login"),
    path("auth/me/", views.profile_view, name="profile"),
    # Bills
    path("bills/", views.BillListCreateView.as_view(), name="bill-list"),
    path("bills/<int:pk>/", views.BillDetailView.as_view(), name="bill-detail"),
]
