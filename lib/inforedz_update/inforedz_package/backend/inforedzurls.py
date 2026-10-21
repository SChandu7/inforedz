from django.urls import path
from . import inforedzviews as views

urlpatterns = [
    path('forgot-password/', views.ForgotPasswordView.as_view(),  name='forgot-password'),
    path('verify-otp/',      views.VerifyOTPView.as_view(),       name='verify-otp'),
    path('reset-password/',  views.ResetPasswordView.as_view(),   name='reset-password'),

    path('register/',   views.RegisterView.as_view(),       name='auth-register'),
    path('login/',      views.LoginView.as_view(),          name='auth-login'),
    path('profile/',    views.ProfileView.as_view(),        name='auth-profile'),
    path('location/',   views.UpdateLocationView.as_view(), name='auth-location'),

    path('donors/',                views.DonorListView.as_view(),   name='donor-list'),
    path('donors/map/',            views.DonorMapView.as_view(),    name='donor-map'),
    path('donors/<int:donor_id>/', views.DonorDetailView.as_view(), name='donor-detail'),

    path('blood-banks/',               views.BloodBankListView.as_view(),   name='bank-list'),
    path('blood-banks/map/',           views.BloodBankMapView.as_view(),    name='bank-map'),
    path('blood-banks/stock/',         views.BloodBankStockView.as_view(),  name='bank-stock'),
    path('blood-banks/<int:bank_id>/', views.BloodBankDetailView.as_view(), name='bank-detail'),

    path('stats/',   views.StatsView.as_view(), name='stats'),

    path('requests/',  views.RequestListView.as_view(), name='request-list'),
    path('donations/', views.DonationView.as_view(),    name='donation-list'),
]
