import secrets
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager
from django.utils import timezone


# ─────────────────────────────────────────────────────────────
# CUSTOM USER MANAGER
# ─────────────────────────────────────────────────────────────
class UserManager(BaseUserManager):

    def create_user(self, email, password, **extra):
        if not email:
            raise ValueError("Email is required")
        email = self.normalize_email(email)
        user  = self.model(email=email, **extra)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password, **extra):
        extra.setdefault('is_staff', True)
        extra.setdefault('is_superuser', True)
        return self.create_user(email, password, **extra)


# ─────────────────────────────────────────────────────────────
# USER — single table for both donors and blood banks
# ─────────────────────────────────────────────────────────────
class User(AbstractBaseUser):

    ROLE_CHOICES = [
        ('donor',      'Blood Donor'),
        ('blood_bank', 'Blood Bank'),
    ]

    BLOOD_GROUP_CHOICES = [
        ('A+','A+'), ('A-','A-'),
        ('B+','B+'), ('B-','B-'),
        ('O+','O+'), ('O-','O-'),
        ('AB+','AB+'), ('AB-','AB-'),
    ]

    GENDER_CHOICES = [
        ('Male','Male'),
        ('Female','Female'),
        ('Other','Other'),
    ]

    LAST_DONATED_CHOICES = [
        ('Never', 'Never'),
        ('Less than 3 months ago', 'Less than 3 months ago'),
        ('3-6 months ago', '3-6 months ago'),
        ('More than 6 months ago', 'More than 6 months ago'),
    ]

    # ── core ──────────────────────────────────────────────────
    email        = models.EmailField(unique=True)
    name         = models.CharField(max_length=200)
    role         = models.CharField(max_length=20, choices=ROLE_CHOICES)
    is_active    = models.BooleanField(default=True)
    is_staff     = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)
    created_at   = models.DateTimeField(auto_now_add=True)
    updated_at   = models.DateTimeField(auto_now=True)

    # ── web session token (used by the website; app can adopt later) ──
    auth_token   = models.CharField(max_length=64, blank=True, db_index=True)

    # ── location (shared) ─────────────────────────────────────
    city         = models.CharField(max_length=100, blank=True)
    latitude     = models.FloatField(null=True, blank=True)
    longitude    = models.FloatField(null=True, blank=True)

    # ── donor-specific fields ─────────────────────────────────
    blood_group   = models.CharField(max_length=5, choices=BLOOD_GROUP_CHOICES, blank=True)
    age           = models.PositiveIntegerField(null=True, blank=True)
    gender        = models.CharField(max_length=10, choices=GENDER_CHOICES, blank=True)
    weight        = models.PositiveIntegerField(null=True, blank=True)   # kg
    last_donated  = models.CharField(max_length=50, choices=LAST_DONATED_CHOICES, default='Never', blank=True)
    has_condition = models.BooleanField(default=False)
    is_available  = models.BooleanField(default=True)   # donor live toggle
    donation_count= models.PositiveIntegerField(default=0)

    # ── blood bank-specific fields ────────────────────────────
    bank_name    = models.CharField(max_length=300, blank=True)
    bank_address = models.TextField(blank=True)
    bank_phone   = models.CharField(max_length=20, blank=True)
    timing       = models.CharField(max_length=100, blank=True)
    rating       = models.FloatField(default=0.0)
    is_open      = models.BooleanField(default=True)
    phone        = models.CharField(max_length=20, blank=True)  # donor phone

    USERNAME_FIELD  = 'email'
    REQUIRED_FIELDS = ['name', 'role']

    objects = UserManager()

    class Meta:
        db_table = 'users'
        verbose_name = 'User'

    def __str__(self):
        return f"{self.email} [{self.role}]"

    def has_perm(self, perm, obj=None):
        return self.is_superuser

    def has_module_perms(self, app_label):
        return self.is_superuser

    def issue_token(self):
        """Create/rotate a random session token, used by the website."""
        self.auth_token = secrets.token_urlsafe(32)
        self.save(update_fields=['auth_token'])
        return self.auth_token


# ─────────────────────────────────────────────────────────────
# BLOOD STOCK — separate table for blood bank stock levels
# ─────────────────────────────────────────────────────────────
class BloodStock(models.Model):

    BLOOD_GROUP_CHOICES = [
        ('A+','A+'), ('A-','A-'),
        ('B+','B+'), ('B-','B-'),
        ('O+','O+'), ('O-','O-'),
        ('AB+','AB+'), ('AB-','AB-'),
    ]

    bank        = models.OneToOneField(User, on_delete=models.CASCADE, related_name='stock_record')
    a_pos       = models.PositiveIntegerField(default=0)   # A+
    a_neg       = models.PositiveIntegerField(default=0)   # A-
    b_pos       = models.PositiveIntegerField(default=0)   # B+
    b_neg       = models.PositiveIntegerField(default=0)   # B-
    o_pos       = models.PositiveIntegerField(default=0)   # O+
    o_neg       = models.PositiveIntegerField(default=0)   # O-
    ab_pos      = models.PositiveIntegerField(default=0)   # AB+
    ab_neg      = models.PositiveIntegerField(default=0)   # AB-
    updated_at  = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'blood_stock'

    def __str__(self):
        return f"Stock — {self.bank.bank_name}"

    def to_dict(self):
        """Returns stock as {blood_group: units} dict for API response."""
        return {
            'O+': self.o_pos, 'O-': self.o_neg,
            'A+': self.a_pos, 'A-': self.a_neg,
            'B+': self.b_pos, 'B-': self.b_neg,
            'AB+': self.ab_pos, 'AB-': self.ab_neg,
        }

    def update_from_dict(self, data: dict):
        """Update stock from {'O+': 45, 'A-': 10, ...} dict."""
        mapping = {
            'O+': 'o_pos', 'O-': 'o_neg',
            'A+': 'a_pos', 'A-': 'a_neg',
            'B+': 'b_pos', 'B-': 'b_neg',
            'AB+': 'ab_pos', 'AB-': 'ab_neg',
        }
        for group, field in mapping.items():
            if group in data:
                try:
                    setattr(self, field, max(0, int(data[group])))
                except (TypeError, ValueError):
                    pass
        self.save()


# ─────────────────────────────────────────────────────────────
# DONATION LOG — track every donation event
# ─────────────────────────────────────────────────────────────
class DonationLog(models.Model):
    donor      = models.ForeignKey(User, on_delete=models.CASCADE, related_name='donations')
    donated_at = models.DateTimeField(default=timezone.now)
    blood_bank = models.CharField(max_length=300, blank=True)
    city       = models.CharField(max_length=100, blank=True)
    notes      = models.TextField(blank=True)

    class Meta:
        db_table = 'donation_logs'
        ordering = ['-donated_at']

    def __str__(self):
        return f"{self.donor.name} donated on {self.donated_at.date()}"


# ─────────────────────────────────────────────────────────────
# BLOOD REQUEST — emergency request board (website)
# ─────────────────────────────────────────────────────────────
class BloodRequest(models.Model):

    URGENCY_CHOICES = [
        ('critical', 'Critical'),
        ('urgent',   'Urgent'),
        ('normal',   'Planned'),
    ]

    STATUS_CHOICES = [
        ('open',      'Open'),
        ('fulfilled', 'Fulfilled'),
        ('cancelled', 'Cancelled'),
    ]

    created_by    = models.ForeignKey(User, on_delete=models.CASCADE, related_name='requests')
    blood_group   = models.CharField(max_length=5, choices=User.BLOOD_GROUP_CHOICES)
    units         = models.PositiveIntegerField(default=1)
    patient_name  = models.CharField(max_length=200)
    hospital      = models.CharField(max_length=300, blank=True)
    city          = models.CharField(max_length=100)
    contact_phone = models.CharField(max_length=20)
    urgency       = models.CharField(max_length=20, choices=URGENCY_CHOICES, default='urgent')
    note          = models.TextField(blank=True)
    latitude      = models.FloatField(null=True, blank=True)
    longitude     = models.FloatField(null=True, blank=True)
    status        = models.CharField(max_length=20, choices=STATUS_CHOICES, default='open')
    created_at    = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'blood_requests'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.blood_group} x{self.units} — {self.city} [{self.status}]"
