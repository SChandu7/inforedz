import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'splash_screen.dart';
import 'donor_tab.dart';
import 'blood_bank_tab.dart';
import 'profile_tab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const InforedzApp());
}

class AppColors {
  static const rose = Color(0xFFCC0000);
  static const roseDark = Color(0xFF8B0000);
  static const roseLight = Color(0xFFFF6666);
  static const rosePale = Color(0xFFFFF0F0);
  static const roseSoft = Color(0xFFFFE4E4);
  static const white = Color(0xFFFFFFFF);
  static const offWhite = Color(0xFFFAFAFA);
  static const bgPage = Color(0xFFF8F3F3);
  static const cardWhite = Color(0xFFFFFFFF);
  static const inkDark = Color(0xFF1A0A0A);
  static const inkMid = Color(0xFF4A2020);
  static const inkLight = Color(0xFF8B5555);
  static const textBody = Color(0xFF2D1515);
  static const textMuted = Color(0xFF9E7070);
  static const divider = Color(0xFFEDD8D8);
  static const success = Color(0xFF1E8A4A);
  static const successBg = Color(0xFFEAF7EF);
  static const warning = Color(0xFFD97706);
  static const warningBg = Color(0xFFFFF7ED);
  static const danger = Color(0xFFDC2626);
  static const shadow = Color(0x14CC0000);
}

class ApiConfig {
  static const baseUrl = 'https://api.chandus7.in/api/inforedz';
  static const googleMapsKey = 'YOUR_GOOGLE_MAPS_API_KEY';
}

class AuthState {
  static int? userId;
  static String? email;
  static String? role;
  static String? name;
  static String? bloodGroup;
  static String? bankName;
  static bool isLoggedIn = false;

  static Future<void> loadFromPrefs() async {
    final p = await SharedPreferences.getInstance();
    userId = p.getInt('userId');
    email = p.getString('email');
    role = p.getString('role');
    name = p.getString('name');
    bloodGroup = p.getString('bloodGroup');
    bankName = p.getString('bankName');
    isLoggedIn = p.getBool('isLoggedIn') ?? false;
  }

  static Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    if (userId != null) await p.setInt('userId', userId!);
    if (email != null) await p.setString('email', email!);
    if (role != null) await p.setString('role', role!);
    if (name != null) await p.setString('name', name!);
    if (bloodGroup != null) await p.setString('bloodGroup', bloodGroup!);
    if (bankName != null) await p.setString('bankName', bankName!);
    await p.setBool('isLoggedIn', isLoggedIn);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    userId = null;
    email = null;
    role = null;
    name = null;
    bloodGroup = null;
    bankName = null;
    isLoggedIn = false;
  }
}

// ── LOCATION SERVICE ──────────────────────────────────────────
class LocationService {
  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<String> getCityFromCoords(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json',
      );
      final res = await http
          .get(uri, headers: {'User-Agent': 'InforedzApp/1.0'})
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        return addr['city'] ??
            addr['town'] ??
            addr['village'] ??
            addr['county'] ??
            addr['state'] ??
            '';
      }
    } catch (_) {}
    return '';
  }
}

// ── ROOT APP ──────────────────────────────────────────────────
class InforedzApp extends StatelessWidget {
  const InforedzApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inforedz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.bgPage,
        primaryColor: AppColors.rose,
        fontFamily: 'Poppins',
        colorScheme: ColorScheme.light(
          primary: AppColors.rose,
          secondary: AppColors.roseDark,
          surface: AppColors.cardWhite,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.rose,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.offWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.rose, width: 1.5),
          ),
          labelStyle: const TextStyle(color: AppColors.inkLight),
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// ── HOME SCREEN ───────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  final _pages = const [DonorTab(), BloodBankTab(), ProfileTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _navItem(0, Icons.volunteer_activism_rounded, 'Donate Blood'),
              _navItem(1, Icons.local_hospital_rounded, 'Blood Banks'),
              _navItem(2, Icons.person_rounded, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label) {
    final active = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = idx),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: active ? AppColors.rosePale : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: active ? AppColors.rose : AppColors.textMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? AppColors.rose : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AUTH SCREEN ───────────────────────────────────────────────
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  String _role = 'donor';
  bool _loading = false;
  bool _obscure = true;
  bool _locLoading = false;
  String _locStatus = '';
  double? _capturedLat;
  double? _capturedLng;

  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _bloodCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _bankAddressCtrl = TextEditingController();
  final _bankPhoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String _gender = 'Male';
  String _lastDonated = 'Never';
  bool _hasCondition = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    _bloodCtrl.dispose();
    _bankNameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _bankAddressCtrl.dispose();
    _bankPhoneCtrl.dispose();
    _cityCtrl.dispose();
    _phoneCtrl.dispose();

    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() {
      _locLoading = true;
      _locStatus = 'Detecting your location...';
    });
    final pos = await LocationService.getCurrentPosition();
    if (pos != null) {
      _capturedLat = pos.latitude;
      _capturedLng = pos.longitude;
      final city = await LocationService.getCityFromCoords(
        pos.latitude,
        pos.longitude,
      );
      _cityCtrl.text = city;
      setState(() {
        _locStatus =
            '✓ ${city.isNotEmpty ? city : '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'}';
        _locLoading = false;
      });
    } else {
      setState(() {
        _locStatus = 'GPS unavailable — enter city manually';
        _locLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final endpoint = _isLogin ? '/login/' : '/register/';
      final body = _isLogin
          ? {'email': _emailCtrl.text.trim(), 'password': _passCtrl.text}
          : _buildRegisterBody();
      debugPrint('POST $endpoint => $body');
      final result = await ApiService.post(endpoint, body);
      debugPrint('RESULT => $result');
      if (!mounted) return;
      if (result['success'] == true) {
        final user =
            (result['data'] as Map<String, dynamic>)['user']
                as Map<String, dynamic>;
        AuthState.userId = user['id'];
        AuthState.email = user['email'];
        AuthState.role = user['role'];
        AuthState.name = user['name'];
        AuthState.bloodGroup = user['blood_group'];
        AuthState.bankName = user['bank_name'];
        AuthState.isLoggedIn = true;
        await AuthState.save();
        if (mounted)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
      } else {
        _showError(result['message'] ?? 'Something went wrong');
      }
    } catch (e) {
      debugPrint('ERROR: $e');
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, dynamic> _buildRegisterBody() {
    final base = <String, dynamic>{
      'email': _emailCtrl.text.trim(),
      'password': _passCtrl.text,
      'name': _nameCtrl.text.trim(),
      'role': _role,
      'city': _cityCtrl.text.trim(),
      'latitude': _capturedLat,
      'longitude': _capturedLng,
      'phone': _phoneCtrl.text.trim(), // ← add this
    };
    if (_role == 'donor') {
      base.addAll({
        'blood_group': _bloodCtrl.text.trim(),
        'age': _ageCtrl.text.trim(),
        'gender': _gender,
        'weight': _weightCtrl.text.trim(),
        'last_donated': _lastDonated,
        'has_condition': _hasCondition.toString(),
      });
    } else {
      base.addAll({
        'bank_name': _bankNameCtrl.text.trim(),
        'bank_address': _bankAddressCtrl.text.trim(),
        'bank_phone': _bankPhoneCtrl.text.trim(),
      });
    }
    return base;
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.rose,
      behavior: SnackBarBehavior.floating,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                _header(),
                const SizedBox(height: 32),
                if (!_isLogin) _roleSelector(),
                if (!_isLogin) const SizedBox(height: 20),
                _emailField(),
                const SizedBox(height: 14),
                _passwordField(),
                if (!_isLogin) ...[
                  const SizedBox(height: 14),
                  _nameField(),
                  const SizedBox(height: 16),
                  _locationSection(),
                  const SizedBox(height: 20),
                  if (_role == 'donor') _donorFields(),
                  if (_role == 'blood_bank') _bankFields(),
                ],
                const SizedBox(height: 28),
                _submitBtn(),
                const SizedBox(height: 20),
                _toggle(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.rose,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Info',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.inkDark,
                    fontFamily: 'Poppins',
                  ),
                ),
                TextSpan(
                  text: 'redz',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.rose,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Text(
        _isLogin ? 'Welcome back' : 'Create account',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.inkDark,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        _isLogin
            ? 'Sign in to continue saving lives'
            : 'Join the life-saving community',
        style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
      ),
    ],
  );

  Widget _roleSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'I am registering as',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.inkMid,
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          _roleChip('donor', Icons.volunteer_activism_rounded, 'Blood Donor'),
          const SizedBox(width: 12),
          _roleChip('blood_bank', Icons.local_hospital_rounded, 'Blood Bank'),
        ],
      ),
    ],
  );

  Widget _roleChip(String val, IconData icon, String label) {
    final sel = _role == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: sel ? AppColors.rosePale : AppColors.offWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel ? AppColors.rose : AppColors.divider,
              width: sel ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: sel ? AppColors.rose : AppColors.textMuted,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: sel ? AppColors.rose : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── LOCATION SECTION ────────────────────────────────────────
  // add this at top of _AuthScreenState fields
  List<Map<String, dynamic>> _citySuggestions = [];
  bool _citySearching = false;

  Future<List<Map<String, dynamic>>> _searchCities(String query) async {
    if (query.length < 3) return [];
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&addressdetails=1&limit=5&countrycodes=in',
      );
      final res = await http
          .get(uri, headers: {'User-Agent': 'InforedzApp/1.0'})
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list
            .map(
              (e) => {
                'display': e['display_name'] ?? '',
                'short':
                    (e['address']?['city'] ??
                    e['address']?['town'] ??
                    e['address']?['village'] ??
                    e['address']?['county'] ??
                    query),
                'lat': double.tryParse(e['lat'] ?? '') ?? 0.0,
                'lng': double.tryParse(e['lon'] ?? '') ?? 0.0,
              },
            )
            .toList();
      }
    } catch (_) {}
    return [];
  }

  Widget _locationSection() {
    final hasLoc = _capturedLat != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // section label
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.rosePale,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📍 Your Location',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.roseDark,
                ),
              ),
              Text(
                'Search your city — required to appear on the map',
                style: TextStyle(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── CITY SEARCH with autocomplete ──────────────────────
        TypeAheadField<Map<String, dynamic>>(
          controller: _cityCtrl,
          builder: (context, controller, focusNode) => TextFormField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 14, color: AppColors.textBody),
            decoration: InputDecoration(
              labelText: 'Search city or area',
              prefixIcon: const Icon(Icons.location_city_outlined, size: 18),
              suffixIcon: hasLoc
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 20,
                    )
                  : _citySearching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.rose,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
              helperText: hasLoc
                  ? '✓ Coordinates saved — you will appear on map'
                  : 'Type at least 3 letters to see suggestions',
              helperStyle: TextStyle(
                fontSize: 10,
                color: hasLoc ? AppColors.success : AppColors.textMuted,
              ),
              helperMaxLines: 2,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'City is required' : null,
          ),
          suggestionsCallback: (query) async {
            setState(() => _citySearching = true);
            final results = await _searchCities(query);
            setState(() => _citySearching = false);
            return results;
          },
          itemBuilder: (context, suggestion) => ListTile(
            leading: const Icon(
              Icons.location_on_rounded,
              color: AppColors.rose,
              size: 18,
            ),
            title: Text(
              suggestion['short'],
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textBody,
              ),
            ),
            subtitle: Text(
              suggestion['display'],
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          onSelected: (suggestion) {
            setState(() {
              _cityCtrl.text = suggestion['short'];
              _capturedLat = suggestion['lat'];
              _capturedLng = suggestion['lng'];
              _locStatus = '✓ ${suggestion['short']}';
            });
            FocusScope.of(context).unfocus();
          },
          emptyBuilder: (_) => const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No results — try a different spelling',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          loadingBuilder: (_) => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.rose,
                strokeWidth: 2,
              ),
            ),
          ),
          decorationBuilder: (context, child) => Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: child,
            ),
          ),
        ),

        // ── GPS fallback button ─────────────────────────────────
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _locLoading ? null : _detectLocation,
          child: Row(
            children: [
              _locLoading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.rose,
                      ),
                    )
                  : Icon(
                      Icons.my_location_rounded,
                      size: 14,
                      color: hasLoc ? AppColors.success : AppColors.rose,
                    ),
              const SizedBox(width: 6),
              Text(
                _locLoading
                    ? 'Detecting GPS...'
                    : hasLoc
                    ? 'Re-detect using GPS'
                    : 'Or use GPS auto-detect instead',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: hasLoc ? AppColors.success : AppColors.rose,
                ),
              ),
            ],
          ),
        ),

        // ── confirmed location pill ─────────────────────────────
        if (hasLoc) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_cityCtrl.text}  •  ${_capturedLat!.toStringAsFixed(4)}, ${_capturedLng!.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ),
                const Icon(
                  Icons.map_rounded,
                  size: 14,
                  color: AppColors.success,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _emailField() => TextFormField(
    controller: _emailCtrl,
    keyboardType: TextInputType.emailAddress,
    decoration: const InputDecoration(
      labelText: 'Email address',
      prefixIcon: Icon(Icons.email_outlined, size: 20),
    ),
    validator: (v) =>
        (v == null || !v.contains('@')) ? 'Enter valid email' : null,
  );

  Widget _passwordField() => TextFormField(
    controller: _passCtrl,
    obscureText: _obscure,
    decoration: InputDecoration(
      labelText: 'Password',
      prefixIcon: const Icon(Icons.lock_outline, size: 20),
      suffixIcon: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    ),
    validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
  );

  Widget _nameField() => TextFormField(
    controller: _nameCtrl,
    decoration: InputDecoration(
      labelText: _role == 'donor' ? 'Your full name' : 'Contact person name',
      prefixIcon: const Icon(Icons.person_outline, size: 20),
    ),
    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
  );

  Widget _donorFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('🩸 Donor Details'),
      const SizedBox(height: 12),
      _bloodGroupDropdown(),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _ageCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                prefixIcon: Icon(Icons.cake_outlined, size: 18),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _weightCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
                prefixIcon: Icon(Icons.monitor_weight_outlined, size: 18),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _genderSelector(),
      const SizedBox(height: 12),
      _lastDonatedDropdown(),
      const SizedBox(height: 12),
      const SizedBox(height: 14),
      TextFormField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'Mobile number',
          prefixIcon: Icon(Icons.phone_outlined, size: 18),
          hintText: '+91 98765 43210',
        ),
        validator: (v) => (v == null || v.trim().length < 10)
            ? 'Enter valid mobile number'
            : null,
      ),
    ],
  );

  Widget _bankFields() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionLabel('🏥 Blood Bank Details'),
      const SizedBox(height: 12),
      TextFormField(
        controller: _bankNameCtrl,
        decoration: const InputDecoration(
          labelText: 'Blood bank / organisation name',
          prefixIcon: Icon(Icons.business_outlined, size: 18),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _bankAddressCtrl,
        maxLines: 2,
        decoration: const InputDecoration(
          labelText: 'Full address',
          prefixIcon: Icon(Icons.location_on_outlined, size: 18),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      ),
      const SizedBox(height: 12),
      TextFormField(
        controller: _bankPhoneCtrl,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'Contact phone number',
          prefixIcon: Icon(Icons.phone_outlined, size: 18),
        ),
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
      ),
    ],
  );

  Widget _sectionLabel(String t) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.rosePale,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      t,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.roseDark,
      ),
    ),
  );

  Widget _bloodGroupDropdown() {
    const groups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
    return DropdownButtonFormField<String>(
      value: _bloodCtrl.text.isEmpty ? null : _bloodCtrl.text,
      decoration: const InputDecoration(
        labelText: 'Blood group',
        prefixIcon: Icon(Icons.water_drop_outlined, size: 18),
      ),
      items: groups
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
      onChanged: (v) {
        if (v != null) _bloodCtrl.text = v;
      },
      validator: (v) => v == null ? 'Select blood group' : null,
    );
  }

  Widget _genderSelector() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Gender',
        style: TextStyle(fontSize: 12, color: AppColors.inkLight),
      ),
      const SizedBox(height: 8),
      Row(
        children: ['Male', 'Female', 'Other'].map((g) {
          final sel = _gender == g;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(() => _gender = g),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: sel ? AppColors.rosePale : AppColors.offWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel ? AppColors.rose : AppColors.divider,
                  ),
                ),
                child: Text(
                  g,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: sel ? AppColors.rose : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );

  Widget _lastDonatedDropdown() {
    const opts = [
      'Never',
      'Less than 3 months ago',
      '3-6 months ago',
      'More than 6 months ago',
    ];
    return DropdownButtonFormField<String>(
      value: _lastDonated,
      decoration: const InputDecoration(
        labelText: 'Last donated blood',
        prefixIcon: Icon(Icons.history_rounded, size: 18),
      ),
      items: opts
          .map(
            (o) => DropdownMenuItem(
              value: o,
              child: Text(o, style: const TextStyle(fontSize: 13)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _lastDonated = v);
      },
    );
  }

  Widget _conditionToggle() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.offWhite,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.divider),
    ),
    child: Row(
      children: [
        const Icon(
          Icons.medical_information_outlined,
          size: 18,
          color: AppColors.inkLight,
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'I have any chronic medical condition',
            style: TextStyle(fontSize: 13, color: AppColors.textBody),
          ),
        ),
        Switch.adaptive(
          value: _hasCondition,
          onChanged: (v) => setState(() => _hasCondition = v),
          activeColor: AppColors.rose,
        ),
      ],
    ),
  );

  Widget _submitBtn() => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      onPressed: _loading ? null : _submit,
      child: _loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : Text(_isLogin ? 'Sign In' : 'Create Account'),
    ),
  );

  Widget _toggle() => Center(
    child: GestureDetector(
      onTap: () => setState(() {
        _isLogin = !_isLogin;
        _capturedLat = null;
        _capturedLng = null;
        _cityCtrl.clear();
        _locStatus = '';
      }),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: _isLogin
                  ? "Don't have an account? "
                  : 'Already have an account? ',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontFamily: 'Poppins',
              ),
            ),
            TextSpan(
              text: _isLogin ? 'Sign Up' : 'Sign In',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.rose,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ── API SERVICE ───────────────────────────────────────────────
class ApiService {
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final res = await http
          .post(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      return _parse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? params,
  }) async {
    try {
      var uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      if (params != null) uri = uri.replace(queryParameters: params);
      final res = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      return _parse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      final res = await http
          .patch(uri, headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      return _parse(res);
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Map<String, dynamic> _parse(http.Response res) {
    try {
      final decoded = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode >= 200 && res.statusCode < 300)
        return {'success': true, ...decoded};
      return {
        'success': false,
        'message':
            decoded['message'] ??
            decoded['detail'] ??
            'Error ${res.statusCode}',
      };
    } catch (_) {
      return {'success': false, 'message': 'Invalid server response'};
    }
  }
}

// ── SHARED WIDGETS ────────────────────────────────────────────
class InfoRedzAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  const InfoRedzAppBar({super.key, required this.title, this.actions});
  @override
  Size get preferredSize => const Size.fromHeight(60);
  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: AppColors.white,
    elevation: 0,
    title: RichText(
      text: TextSpan(
        children: title == 'Inforedz'
            ? const [
                TextSpan(
                  text: 'Info',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.inkDark,
                    fontFamily: 'Poppins',
                  ),
                ),
                TextSpan(
                  text: 'redz',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.rose,
                    fontFamily: 'Poppins',
                  ),
                ),
              ]
            : [
                TextSpan(
                  text: title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkDark,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
      ),
    ),
    actions: actions,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: AppColors.divider),
    ),
  );
}

class BloodBadge extends StatelessWidget {
  final String type;
  final double size;
  const BloodBadge({super.key, required this.type, this.size = 13});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: size * 0.7, vertical: size * 0.3),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.rose, AppColors.roseDark],
      ),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      type,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: Colors.white,
      ),
    ),
  );
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderColor,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? AppColors.divider,
          width: borderColor != null ? 1.5 : 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    ),
  );
}
