import json
from django.http import JsonResponse
from django.views import View
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from django.utils import timezone
from django.db.models import Q
from .inforedzmodels import User, BloodStock, DonationLog, BloodRequest


# ── HELPERS ───────────────────────────────────────────────────

def json_body(request):
    try:
        return json.loads(request.body)
    except (json.JSONDecodeError, TypeError):
        return {}

def ok(data=None, **kwargs):
    payload = {'success': True}
    if data is not None:
        payload['data'] = data
    payload.update(kwargs)
    return JsonResponse(payload, status=200)

def created(data=None, **kwargs):
    payload = {'success': True}
    if data is not None:
        payload['data'] = data
    payload.update(kwargs)
    return JsonResponse(payload, status=201)

def err(message, status=400):
    return JsonResponse({'success': False, 'message': message}, status=status)

def get_user_by_id(user_id):
    """Public lookup by id — unchanged from the original app backend."""
    if not user_id:
        return None, err('user_id is required.', 400)
    try:
        user = User.objects.get(id=int(user_id), is_active=True)
        return user, None
    except (User.DoesNotExist, ValueError, TypeError):
        return None, err('User not found.', 404)

def get_web_user(request, user_id):
    """
    Website write-path auth.
    If the request carries X-Auth-Token, it MUST match the user's token.
    If it does not (e.g. the current Flutter app, which doesn't send one),
    fall back to id-only lookup so the app keeps working until it's updated.
    """
    token = request.headers.get('X-Auth-Token', '')
    user, error = get_user_by_id(user_id)
    if error:
        return None, error
    if token and user.auth_token and token != user.auth_token:
        return None, err('Invalid or expired session.', 401)
    return user, None

def serialize_donor(user, include_contact=True):
    data = {
        'id':            user.id,
        'name':          user.name,
        'email':         user.email,
        'role':          user.role,
        'blood_group':   user.blood_group,
        'city':          user.city,
        'age':           user.age,
        'gender':        user.gender,
        'weight':        user.weight,
        'last_donated':  user.last_donated,
        'has_condition': user.has_condition,
        'is_available':  user.is_available,
        'donation_count':user.donation_count,
        'latitude':      user.latitude,
        'longitude':     user.longitude,
        'created_at':    str(user.created_at.date()) if user.created_at else None,
    }
    if include_contact:
        data['phone'] = user.phone
    return data

def serialize_bank(user):
    try:
        stock = user.stock_record.to_dict()
    except BloodStock.DoesNotExist:
        stock = {g: 0 for g in ['O+','O-','A+','A-','B+','B-','AB+','AB-']}
    return {
        'id':           user.id,
        'name':         user.name,
        'email':        user.email,
        'role':         user.role,
        'bank_name':    user.bank_name,
        'bank_address': user.bank_address,
        'bank_phone':   user.bank_phone,
        'city':         user.city,
        'timing':       user.timing,
        'rating':       user.rating,
        'is_open':      user.is_open,
        'latitude':     user.latitude,
        'longitude':    user.longitude,
        'stock':        stock,
        'created_at':   str(user.created_at.date()) if user.created_at else None,
    }

def serialize_request(r):
    return {
        'id':            r.id,
        'blood_group':   r.blood_group,
        'units':         r.units,
        'patient_name':  r.patient_name,
        'hospital':      r.hospital,
        'city':          r.city,
        'contact_phone': r.contact_phone,
        'urgency':       r.urgency,
        'note':          r.note,
        'latitude':      r.latitude,
        'longitude':     r.longitude,
        'status':        r.status,
        'created_by':    r.created_by_id,
        'created_at':    r.created_at.isoformat(),
    }

def _safe_float(val):
    try: return float(val)
    except (TypeError, ValueError): return None

def _safe_int(val):
    try: return int(val)
    except (TypeError, ValueError): return None


# ── REGISTER ──────────────────────────────────────────────────
# POST /api/inforedz/register/
@method_decorator(csrf_exempt, name='dispatch')
class RegisterView(View):
    def post(self, request):
        data     = json_body(request)
        email    = data.get('email', '').strip().lower()
        password = data.get('password', '')
        name     = data.get('name', '').strip()
        role     = data.get('role', '')

        if not email:    return err('email is required.')
        if not password: return err('password is required.')
        if not name:     return err('name is required.')
        if role not in ('donor', 'blood_bank'):
            return err("role must be 'donor' or 'blood_bank'.")
        if len(password) < 6:
            return err('Password must be at least 6 characters.')
        if User.objects.filter(email=email).exists():
            return err('An account with this email already exists.')

        try:
            user           = User(email=email, name=name, role=role)
            user.set_password(password)
            user.city      = data.get('city', '').strip()
            user.latitude  = _safe_float(data.get('latitude'))
            user.longitude = _safe_float(data.get('longitude'))

            if role == 'donor':
                user.blood_group   = data.get('blood_group', '').strip()
                user.age           = _safe_int(data.get('age'))
                user.gender        = data.get('gender', 'Male')
                user.weight        = _safe_int(data.get('weight'))
                user.last_donated  = data.get('last_donated', 'Never')
                user.has_condition = str(data.get('has_condition', 'false')).lower() == 'true'
                user.is_available  = True
                user.phone         = data.get('phone', '').strip()
                if not user.blood_group:
                    return err('blood_group is required for donors.')

            elif role == 'blood_bank':
                user.bank_name    = data.get('bank_name', '').strip()
                user.bank_address = data.get('bank_address', '').strip()
                user.bank_phone   = data.get('bank_phone', '').strip()
                user.timing       = data.get('timing', '').strip()
                user.is_open      = True
                if not user.bank_name:
                    return err('bank_name is required for blood banks.')

            user.save()

            if role == 'blood_bank':
                BloodStock.objects.create(bank=user)

            payload = serialize_donor(user) if role == 'donor' else serialize_bank(user)
            payload['auth_token'] = user.issue_token()   # website uses this; app can ignore it
            return created(data={'user': payload}, message='Registration successful.')

        except Exception as e:
            return err(f'Registration failed: {str(e)}', 500)


# ── LOGIN ─────────────────────────────────────────────────────
# POST /api/inforedz/login/
@method_decorator(csrf_exempt, name='dispatch')
class LoginView(View):
    def post(self, request):
        data     = json_body(request)
        email    = data.get('email', '').strip().lower()
        password = data.get('password', '')

        if not email or not password:
            return err('email and password are required.')

        try:
            user = User.objects.get(email=email, is_active=True)
        except User.DoesNotExist:
            return err('Invalid email or password.')

        if not user.check_password(password):
            return err('Invalid email or password.')

        payload = serialize_donor(user) if user.role == 'donor' else serialize_bank(user)
        payload['auth_token'] = user.issue_token()
        return ok(data={'user': payload}, message='Login successful.')


# ── PROFILE ───────────────────────────────────────────────────
# GET   /api/inforedz/profile/?user_id=1
# PATCH /api/inforedz/profile/   Body: { user_id, ...fields }
@method_decorator(csrf_exempt, name='dispatch')
class ProfileView(View):

    def get(self, request):
        user, error = get_user_by_id(request.GET.get('user_id'))
        if error: return error
        payload = serialize_donor(user) if user.role == 'donor' else serialize_bank(user)
        return ok(data=payload)

    def patch(self, request):
        data = json_body(request)
        user, error = get_web_user(request, data.get('user_id'))
        if error: return error

        try:
            if 'name'      in data: user.name      = str(data['name']).strip()
            if 'city'      in data: user.city      = str(data['city']).strip()
            if 'latitude'  in data: user.latitude  = _safe_float(data['latitude'])
            if 'longitude' in data: user.longitude = _safe_float(data['longitude'])

            if user.role == 'donor':
                if 'blood_group'   in data: user.blood_group   = data['blood_group']
                if 'age'           in data: user.age           = _safe_int(data['age'])
                if 'gender'        in data: user.gender        = data['gender']
                if 'weight'        in data: user.weight        = _safe_int(data['weight'])
                if 'last_donated'  in data: user.last_donated  = data['last_donated']
                if 'has_condition' in data: user.has_condition = bool(data['has_condition'])
                if 'is_available'  in data: user.is_available  = bool(data['is_available'])

            elif user.role == 'blood_bank':
                if 'bank_name'    in data: user.bank_name    = str(data['bank_name']).strip()
                if 'bank_address' in data: user.bank_address = str(data['bank_address']).strip()
                if 'bank_phone'   in data: user.bank_phone   = str(data['bank_phone']).strip()
                if 'timing'       in data: user.timing       = str(data['timing']).strip()
                if 'is_open'      in data: user.is_open      = bool(data['is_open'])
                if 'stock' in data and isinstance(data['stock'], dict):
                    stock_obj, _ = BloodStock.objects.get_or_create(bank=user)
                    stock_obj.update_from_dict(data['stock'])

            user.save()
            payload = serialize_donor(user) if user.role == 'donor' else serialize_bank(user)
            return ok(data=payload, message='Profile updated successfully.')

        except Exception as e:
            return err(f'Update failed: {str(e)}', 500)


# ── UPDATE LOCATION ───────────────────────────────────────────
# POST /api/inforedz/location/
@method_decorator(csrf_exempt, name='dispatch')
class UpdateLocationView(View):
    def post(self, request):
        data = json_body(request)
        user, error = get_web_user(request, data.get('user_id'))
        if error: return error

        lat  = _safe_float(data.get('latitude'))
        lng  = _safe_float(data.get('longitude'))
        city = data.get('city', '').strip()

        if lat is None or lng is None:
            return err('latitude and longitude are required.')

        user.latitude  = lat
        user.longitude = lng
        if city: user.city = city
        user.save(update_fields=['latitude', 'longitude', 'city'])
        return ok(message='Location updated.')


# ── DONORS LIST ───────────────────────────────────────────────
# GET /api/inforedz/donors/
@method_decorator(csrf_exempt, name='dispatch')
class DonorListView(View):
    def get(self, request):
        qs          = User.objects.filter(role='donor', is_active=True)
        blood_group = request.GET.get('blood_group', '').strip()
        city        = request.GET.get('city', '').strip()
        available   = request.GET.get('available', '').strip().lower()
        search      = request.GET.get('search', '').strip()

        if blood_group: qs = qs.filter(blood_group=blood_group)
        if city:        qs = qs.filter(city__icontains=city)
        if available == 'true': qs = qs.filter(is_available=True)
        if search:
            qs = qs.filter(
                Q(name__icontains=search) |
                Q(city__icontains=search) |
                Q(blood_group__icontains=search)
            )

        # Phone is included only for signed-in web users (token present).
        include_contact = bool(request.headers.get('X-Auth-Token'))
        return ok(data=[serialize_donor(d, include_contact=include_contact) for d in qs.order_by('name')])


# ── DONORS MAP ────────────────────────────────────────────────
# GET /api/inforedz/donors/map/
@method_decorator(csrf_exempt, name='dispatch')
class DonorMapView(View):
    def get(self, request):
        donors = User.objects.filter(
            role='donor', is_active=True, is_available=True,
            latitude__isnull=False, longitude__isnull=False,
        ).values('id', 'name', 'blood_group', 'city', 'is_available', 'latitude', 'longitude')
        return ok(data=list(donors))


# ── DONOR DETAIL ──────────────────────────────────────────────
# GET /api/inforedz/donors/<id>/
@method_decorator(csrf_exempt, name='dispatch')
class DonorDetailView(View):
    def get(self, request, donor_id):
        try:
            user = User.objects.get(id=donor_id, role='donor', is_active=True)
        except User.DoesNotExist:
            return err('Donor not found.', 404)
        include_contact = bool(request.headers.get('X-Auth-Token'))
        return ok(data=serialize_donor(user, include_contact=include_contact))


# ── BLOOD BANKS LIST ──────────────────────────────────────────
# GET /api/inforedz/blood-banks/
@method_decorator(csrf_exempt, name='dispatch')
class BloodBankListView(View):
    def get(self, request):
        qs          = User.objects.filter(role='blood_bank', is_active=True)
        city        = request.GET.get('city', '').strip()
        search      = request.GET.get('search', '').strip()
        blood_group = request.GET.get('blood_group', '').strip()

        if city:   qs = qs.filter(city__icontains=city)
        if search: qs = qs.filter(Q(bank_name__icontains=search) | Q(city__icontains=search))

        banks = []
        for bank in qs.order_by('bank_name'):
            data = serialize_bank(bank)
            if blood_group and data.get('stock', {}).get(blood_group, 0) <= 0:
                continue
            banks.append(data)
        return ok(data=banks)


# ── BLOOD BANKS MAP ───────────────────────────────────────────
# GET /api/inforedz/blood-banks/map/
@method_decorator(csrf_exempt, name='dispatch')
class BloodBankMapView(View):
    def get(self, request):
        banks = User.objects.filter(
            role='blood_bank', is_active=True,
            latitude__isnull=False, longitude__isnull=False,
        ).values('id', 'bank_name', 'city', 'is_open', 'latitude', 'longitude', 'rating')
        return ok(data=list(banks))


# ── BLOOD BANK DETAIL ─────────────────────────────────────────
# GET /api/inforedz/blood-banks/<id>/
@method_decorator(csrf_exempt, name='dispatch')
class BloodBankDetailView(View):
    def get(self, request, bank_id):
        try:
            return ok(data=serialize_bank(User.objects.get(id=bank_id, role='blood_bank', is_active=True)))
        except User.DoesNotExist:
            return err('Blood bank not found.', 404)


# ── BLOOD BANK STOCK UPDATE ───────────────────────────────────
# PATCH /api/inforedz/blood-banks/stock/
@method_decorator(csrf_exempt, name='dispatch')
class BloodBankStockView(View):
    def patch(self, request):
        data = json_body(request)
        user, error = get_web_user(request, data.get('user_id'))
        if error: return error
        if user.role != 'blood_bank':
            return err('Only blood bank accounts can update stock.', 403)
        try:
            stock_obj, _ = BloodStock.objects.get_or_create(bank=user)
            stock_obj.update_from_dict(data)
            return ok(data=stock_obj.to_dict(), message='Stock updated successfully.')
        except Exception as e:
            return err(f'Stock update failed: {str(e)}', 500)


# ── STATS ─────────────────────────────────────────────────────
# GET /api/inforedz/stats/
@method_decorator(csrf_exempt, name='dispatch')
class StatsView(View):
    def get(self, request):
        return ok(data={
            'total_donors':     User.objects.filter(role='donor', is_active=True).count(),
            'available_donors': User.objects.filter(role='donor', is_active=True, is_available=True).count(),
            'total_banks':      User.objects.filter(role='blood_bank', is_active=True).count(),
            'open_banks':       User.objects.filter(role='blood_bank', is_active=True, is_open=True).count(),
            'cities':           User.objects.filter(is_active=True).exclude(city='').values_list('city', flat=True).distinct().count(),
            'total_donations':  DonationLog.objects.count(),
        })


# ── BLOOD REQUESTS ────────────────────────────────────────────
# GET   /api/inforedz/requests/    params: blood_group, city, status
# POST  /api/inforedz/requests/    body: created_by (or user_id) + fields
# PATCH /api/inforedz/requests/    body: user_id, request_id, status
@method_decorator(csrf_exempt, name='dispatch')
class RequestListView(View):

    def get(self, request):
        qs     = BloodRequest.objects.select_related('created_by')
        bg     = request.GET.get('blood_group', '').strip()
        city   = request.GET.get('city', '').strip()
        status = request.GET.get('status', '').strip()

        if bg:     qs = qs.filter(blood_group=bg)
        if city:   qs = qs.filter(city__icontains=city)
        if status: qs = qs.filter(status=status)

        return ok(data=[serialize_request(r) for r in qs[:200]])

    def post(self, request):
        data = json_body(request)
        user, error = get_web_user(request, data.get('created_by') or data.get('user_id'))
        if error: return error

        patient = data.get('patient_name', '').strip()
        city    = data.get('city', '').strip()
        phone   = data.get('contact_phone', '').strip()
        if not patient: return err('patient_name is required.')
        if not city:    return err('city is required.')
        if not phone:   return err('contact_phone is required.')

        try:
            r = BloodRequest.objects.create(
                created_by    = user,
                blood_group   = data.get('blood_group', ''),
                units         = _safe_int(data.get('units')) or 1,
                patient_name  = patient,
                hospital      = data.get('hospital', '').strip(),
                city          = city,
                contact_phone = phone,
                urgency       = data.get('urgency', 'urgent'),
                note          = data.get('note', '').strip(),
                latitude      = _safe_float(data.get('latitude')),
                longitude     = _safe_float(data.get('longitude')),
            )
            return created(data=serialize_request(r), message='Request posted.')
        except Exception as e:
            return err(f'Could not post request: {str(e)}', 500)

    def patch(self, request):
        data = json_body(request)
        user, error = get_web_user(request, data.get('user_id'))
        if error: return error

        try:
            r = BloodRequest.objects.get(id=int(data.get('request_id')))
        except (BloodRequest.DoesNotExist, ValueError, TypeError):
            return err('Request not found.', 404)

        if r.created_by_id != user.id:
            return err('You can only update your own request.', 403)

        status = data.get('status', 'fulfilled')
        if status not in dict(BloodRequest.STATUS_CHOICES):
            return err('Invalid status.')

        r.status = status
        r.save(update_fields=['status'])
        return ok(data=serialize_request(r), message='Request updated.')


# ── DONATION HISTORY ──────────────────────────────────────────
# GET  /api/inforedz/donations/?user_id=1
# POST /api/inforedz/donations/   body: donor (or user_id) + fields
@method_decorator(csrf_exempt, name='dispatch')
class DonationView(View):

    def get(self, request):
        user, error = get_user_by_id(request.GET.get('user_id'))
        if error: return error
        rows = DonationLog.objects.filter(donor=user)
        return ok(data=[{
            'id':         d.id,
            'donor':      d.donor_id,
            'donated_at': str(d.donated_at.date()),
            'blood_bank': d.blood_bank,
            'city':       d.city,
            'notes':      d.notes,
        } for d in rows])

    def post(self, request):
        data = json_body(request)
        user, error = get_web_user(request, data.get('donor') or data.get('user_id'))
        if error: return error

        try:
            log = DonationLog.objects.create(
                donor      = user,
                donated_at = data.get('donated_at') or timezone.now(),
                blood_bank = data.get('blood_bank', '').strip(),
                city       = data.get('city', '').strip(),
                notes      = data.get('notes', '').strip(),
            )
            user.donation_count = (user.donation_count or 0) + 1
            user.last_donated   = 'Less than 3 months ago'
            user.save(update_fields=['donation_count', 'last_donated'])

            return created(data={
                'id':         log.id,
                'donor':      user.id,
                'donated_at': str(log.donated_at.date()),
                'blood_bank': log.blood_bank,
                'city':       log.city,
                'notes':      log.notes,
            }, message='Donation logged.')
        except Exception as e:
            return err(f'Could not log donation: {str(e)}', 500)
