from django.urls import path
from . import inforedzviews as views

# ─────────────────────────────────────────────────────────────
# All API endpoints. Whatever prefix your project urls.py mounts
# this under (e.g. path('api/inforedz/', include('inforedz.inforedzurls'))),
# the website's CONFIG.API_BASE must match it exactly.
# ─────────────────────────────────────────────────────────────
urlpatterns = [

    # ── AUTH ──────────────────────────────────────────────────
    path('register/',   views.RegisterView.as_view(),       name='auth-register'),
    path('login/',      views.LoginView.as_view(),          name='auth-login'),
    path('profile/',    views.ProfileView.as_view(),        name='auth-profile'),
    path('location/',   views.UpdateLocationView.as_view(), name='auth-location'),

    # ── DONORS (public) ───────────────────────────────────────
    path('donors/',                views.DonorListView.as_view(),   name='donor-list'),
    path('donors/map/',            views.DonorMapView.as_view(),    name='donor-map'),
    path('donors/<int:donor_id>/', views.DonorDetailView.as_view(), name='donor-detail'),

    # ── BLOOD BANKS (public) ──────────────────────────────────
    path('blood-banks/',               views.BloodBankListView.as_view(),   name='bank-list'),
    path('blood-banks/map/',           views.BloodBankMapView.as_view(),    name='bank-map'),
    path('blood-banks/stock/',         views.BloodBankStockView.as_view(),  name='bank-stock'),
    path('blood-banks/<int:bank_id>/', views.BloodBankDetailView.as_view(), name='bank-detail'),

    # ── STATS (public) ────────────────────────────────────────
    path('stats/',   views.StatsView.as_view(), name='stats'),

    # ── REQUESTS & DONATIONS (website) ────────────────────────
    path('requests/',  views.RequestListView.as_view(), name='request-list'),
    path('donations/', views.DonationView.as_view(),    name='donation-list'),
]
