import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'main.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────
// DONOR MODEL
// ─────────────────────────────────────────────────────────────
class DonorModel {
  final int id;
  final String name, bloodGroup, city, gender, lastDonated, email;
  final int age, weight, donations;
  final String phone; // ← add

  final bool available, hasCondition;
  final double? lat, lng;

  const DonorModel({
    required this.id,
    required this.name,
    required this.bloodGroup,
    required this.city,
    required this.gender,
    required this.lastDonated,
    required this.email,
    required this.age,
    required this.weight,
    required this.donations,
    required this.phone, // ← add

    required this.available,
    required this.hasCondition,
    this.lat,
    this.lng,
  });

  factory DonorModel.fromJson(Map<String, dynamic> j) => DonorModel(
    id: j['id'],
    name: j['name'] ?? '',
    bloodGroup: j['blood_group'] ?? '',
    city: j['city'] ?? '',
    gender: j['gender'] ?? '',
    lastDonated: j['last_donated'] ?? '',
    email: j['email'] ?? '',
    age: j['age'] ?? 0,
    weight: j['weight'] ?? 0,
    donations: j['donation_count'] ?? 0,
    phone: j['phone'] ?? '', // ← add

    available: j['is_available'] ?? false,
    hasCondition: j['has_condition'] ?? false,
    lat: (j['latitude'] as num?)?.toDouble(),
    lng: (j['longitude'] as num?)?.toDouble(),
  );

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ─────────────────────────────────────────────────────────────
// DONOR TAB
// ─────────────────────────────────────────────────────────────
class DonorTab extends StatefulWidget {
  const DonorTab({super.key});
  @override
  State<DonorTab> createState() => _DonorTabState();
}

class _DonorTabState extends State<DonorTab> {
  List<DonorModel> _allDonors = [];
  List<DonorModel> _filtered = [];
  bool _loading = true;
  String _selectedGroup = 'All';
bool _showOnlyAvailable = false;   // ← add
final _searchCtrl = TextEditingController();
final _types = ['All', 'O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];
  Timer? _debounce;

  bool _initialLoadDone = false;

@override
void initState() {
  super.initState();
  _searchCtrl.addListener(_onSearch);
  _loadDonors();
}

@override
void didChangeDependencies() {
  super.didChangeDependencies();
  // only silent refresh after first load — never resets order
  if (_initialLoadDone) {
    _silentRefresh();
  }
}

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

Future<void> _loadDonors() async {
  setState(() => _loading = true);
  try {
    final res = await ApiService.get(
      '/donors/',
      params: {'available': 'all'},
    );
    if (res['success'] == true && mounted) {
      final list = (res['data'] as List)
          .map((e) => DonorModel.fromJson(e))
          .toList();
      setState(() {
        _allDonors = list;
        _initialLoadDone = true;   // ← mark first load done
        _applyFilter();
      });
    }
  } catch (e) {
    debugPrint('❌ loadDonors: $e');
  }
  if (mounted) setState(() => _loading = false);
}

// silent refresh — updates available count WITHOUT resetting list order or showing spinner
Future<void> _silentRefresh() async {
  try {
    final res = await ApiService.get(
      '/donors/',
      params: {'available': 'all'},
    );
    if (res['success'] == true && mounted) {
      final list = (res['data'] as List)
          .map((e) => DonorModel.fromJson(e))
          .toList();
      // preserve existing order — just update availability status
      final updatedMap = {for (final d in list) d.id: d};
      setState(() {
        _allDonors = _allDonors.map((d) {
          return updatedMap[d.id] ?? d;   // update existing, keep order
        }).toList();
        _applyFilter();
      });
    }
  } catch (_) {}
}

  void _onSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _applyFilter);
  }

 void _applyFilter() {
  final q = _searchCtrl.text.toLowerCase();
  setState(() {
    _filtered = _allDonors.where((d) {
      final matchGroup     = _selectedGroup == 'All' || d.bloodGroup == _selectedGroup;
      final matchAvailable = !_showOnlyAvailable || d.available;   // ← add
      final matchSearch    = q.isEmpty ||
          d.name.toLowerCase().contains(q) ||
          d.city.toLowerCase().contains(q) ||
          d.bloodGroup.toLowerCase().contains(q);
      return matchGroup && matchAvailable && matchSearch;
    }).toList();
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: const InfoRedzAppBar(title: 'Inforedz'),
      floatingActionButton: _buildMapFAB(),
      body: Column(
        children: [
          _buildHeroStats(),
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(child: _loading ? _buildLoader() : _buildList()),
        ],
      ),
    );
  }

  Widget _buildMapFAB() {
    return FloatingActionButton.extended(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DonorMapScreen()),
      ),
      backgroundColor: AppColors.rose,
      icon: const Icon(Icons.map_rounded, color: Colors.white),
      label: const Text(
        'View on Map',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      elevation: 4,
    );
  }

  Widget _buildHeroStats() {
    final total = _allDonors.length;
    final available = _allDonors.where((d) => d.available).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.rose, AppColors.roseDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.rose.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _heroStat('$total', 'Total Donors')),
          _heroDivider(),
          Expanded(
            child: _heroStat('$available', 'Available Now'),
          ), // ← live count
          _heroDivider(),
          const Expanded(child: _heroStatStatic('12K+', 'Lives Saved')),
        ],
      ),
    );
  }

  Widget _heroStat(String val, String label) {
    return Column(
      children: [
        Text(
          val,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8)),
        ),
      ],
    );
  }

  Widget _heroDivider() =>
      Container(width: 1, height: 32, color: Colors.white.withOpacity(0.25));

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14, color: AppColors.textBody),
        decoration: InputDecoration(
          hintText: 'Search name, city or blood type...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    _applyFilter();
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.rose, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

 Widget _buildFilterChips() {
  return SizedBox(
    height: 48,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      children: [
        // ── blood type chips ──────────────────────────────
        ..._types.map((t) {
          final sel = t == _selectedGroup;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedGroup = t);
              _applyFilter();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: sel ? AppColors.rose : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? AppColors.rose : AppColors.divider),
                boxShadow: sel ? [BoxShadow(color: AppColors.rose.withOpacity(0.25), blurRadius: 8)] : [],
              ),
              child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: sel ? Colors.white : AppColors.textMuted)),
            ),
          );
        }),

        // ── divider ───────────────────────────────────────
        Container(
          width: 1, height: 24,
          margin: const EdgeInsets.only(right: 8, top: 4),
          color: AppColors.divider,
        ),

        // ── available chip ────────────────────────────────
        GestureDetector(
          onTap: () {
            setState(() => _showOnlyAvailable = !_showOnlyAvailable);
            _applyFilter();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _showOnlyAvailable ? AppColors.success : AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _showOnlyAvailable ? AppColors.success : AppColors.divider),
              boxShadow: _showOnlyAvailable ? [BoxShadow(color: AppColors.success.withOpacity(0.25), blurRadius: 8)] : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _showOnlyAvailable ? Colors.white : AppColors.success,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Available',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _showOnlyAvailable ? Colors.white : AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildList() {
    if (_filtered.isEmpty) return _buildEmpty();
    return RefreshIndicator(
      color: AppColors.rose,
      onRefresh: _loadDonors,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _DonorCard(donor: _filtered[i]),
      ),
    );
  }

  Widget _buildLoader() =>
      const Center(child: CircularProgressIndicator(color: AppColors.rose));

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.search_off_rounded,
          size: 56,
          color: AppColors.rose.withOpacity(0.3),
        ),
        const SizedBox(height: 12),
        const Text(
          'No donors found',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Try different filters',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
      ],
    ),
  );
}

// ignore: must_be_immutable
class _heroStatStatic extends StatelessWidget {
  final String val, label;
  const _heroStatStatic(this.val, this.label);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        val,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
      Text(
        label,
        style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.8)),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────
// DONOR CARD
// ─────────────────────────────────────────────────────────────
class _DonorCard extends StatelessWidget {
  final DonorModel donor;
  const _DonorCard({required this.donor});

  void _callDonor(BuildContext context, String phone) async {
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No phone number available'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // show confirm popup first
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.rosePale,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_rounded,
                color: AppColors.rose,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              donor.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.inkDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              phone,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            BloodBadge(type: donor.bloodGroup),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final uri = Uri(
                    scheme: 'tel',
                    path: phone.replaceAll(' ', ''),
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rose,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.call_rounded, color: Colors.white),
                label: Text(
                  'Call $phone',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: donor.available ? AppColors.rose.withOpacity(0.3) : null,
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 14),
          Expanded(child: _buildInfo(context)),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.rosePale,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.rose.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              donor.initials,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.rose,
              ),
            ),
          ),
        ),
        if (donor.available)
          Positioned(
            right: 1,
            bottom: 1,
            child: Container(
              width: 13,
              height: 13,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                donor.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBody,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            BloodBadge(type: donor.bloodGroup),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 12,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 3),
            Text(
              donor.city,
              style: const TextStyle(fontSize: 12, color: AppColors.inkLight),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.water_drop_rounded,
              size: 12,
              color: AppColors.rose,
            ),
            const SizedBox(width: 3),
            Text(
              '${donor.donations} donations',
              style: const TextStyle(fontSize: 12, color: AppColors.inkLight),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            _availBadge(),
            const Spacer(),
            Text(
              donor.lastDonated,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Builder(
              builder: (ctx) => Expanded(
                child: _actionBtn(
                  Icons.call_rounded,
                  'Call',
                  AppColors.rose,
                  false,
                  () => _callDonor(ctx, donor.phone), // ✅ ctx from Builder
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _actionBtn(
                Icons.chat_bubble_outline_rounded,
                'WhatsApp',
                AppColors.success,
                true,
                () => _openWhatsApp(context, donor.phone),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _openWhatsApp(BuildContext context, String phone) async {
  if (phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No phone number available'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  // clean phone — remove spaces, dashes, brackets
  // add country code 91 if not already present
  String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
  if (!cleaned.startsWith('91') && cleaned.length == 10) {
    cleaned = '91$cleaned';
  }

  final uri = Uri.parse('https://wa.me/$cleaned');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WhatsApp not installed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

  Widget _availBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: donor.available ? AppColors.successBg : const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: donor.available ? AppColors.success : AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          donor.available ? 'Available' : 'Unavailable',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: donor.available ? AppColors.success : AppColors.textMuted,
          ),
        ),
      ],
    ),
  );

  Widget _actionBtn(
    IconData icon,
    String label,
    Color color,
    bool outline,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: outline ? Colors.transparent : color,
          borderRadius: BorderRadius.circular(8),
          border: outline ? Border.all(color: color) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: outline ? color : Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: outline ? color : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DONOR MAP SCREEN — Google Maps with donor + bank pins
// ─────────────────────────────────────────────────────────────
class DonorMapScreen extends StatefulWidget {
  const DonorMapScreen({super.key});
  @override
  State<DonorMapScreen> createState() => _DonorMapScreenState();
}

class _DonorMapScreenState extends State<DonorMapScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  Set<Marker> _markers = {};
  bool _loading = true;
  bool _showDonors = true;
  bool _showBanks = true;
  List<Map<String, dynamic>> _donorData = [];
  List<Map<String, dynamic>> _bankData = [];

 static const _initialCamera = CameraPosition(
  target: LatLng(20.5937, 78.9629),
  zoom: 5,
);

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  Future<void> _loadMapData() async {
    try {
      final dRes = await ApiService.get('/donors/map/');
      final bRes = await ApiService.get('/blood-banks/map/');
      if (!mounted) return; // ← widget was closed, stop here
      if (dRes['success'] == true)
        _donorData = List<Map<String, dynamic>>.from(dRes['data']);
      if (bRes['success'] == true)
        _bankData = List<Map<String, dynamic>>.from(bRes['data']);
    } catch (_) {}
    if (!mounted) return; // ← check again before setState
    _buildMarkers();
    setState(() => _loading = false);
  }

  void _buildMarkers() {
    final markers = <Marker>{};

    if (_showDonors) {
      for (final d in _donorData) {
        // ← only show available donors on map
        if (d['is_available'] != true) continue;
        final lat = (d['latitude'] as num?)?.toDouble();
        final lng = (d['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        markers.add(
          Marker(
            markerId: MarkerId('donor_${d['id']}'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: '${d['name']} · ${d['blood_group']}',
              snippet:
                  '${d['city']} · ${d['is_available'] == true ? "Available" : "Unavailable"}',
            ),
          ),
        );
      }
    }

    if (_showBanks) {
      for (final b in _bankData) {
        final lat = (b['latitude'] as num?)?.toDouble();
        final lng = (b['longitude'] as num?)?.toDouble();
        if (lat == null || lng == null) continue;
        markers.add(
          Marker(
            markerId: MarkerId('bank_${b['id']}'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(
              title: b['bank_name'] ?? '',
              snippet: b['city'] ?? '',
            ),
          ),
        );
      }
    }
    if (!mounted) return; // ← add this before setState

    setState(() => _markers = markers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.inkDark),
        title: const Text(
          'Donors & Blood Banks',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.inkDark,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.rose),
                )
              : GoogleMap(
                  initialCameraPosition: _initialCamera,
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                 onMapCreated: (c) {
  _mapController.complete(c);
  _zoomToUserLocation();   // ← auto zoom on map open
},
                ),
          // Filter toggles
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              children: [
                _filterToggle('🩸 Donors', _showDonors, () {
                  setState(() {
                    _showDonors = !_showDonors;
                    _buildMarkers();
                  });
                }),
                const SizedBox(width: 10),
                _filterToggle('🏥 Blood Banks', _showBanks, () {
                  setState(() {
                    _showBanks = !_showBanks;
                    _buildMarkers();
                  });
                }),
              ],
            ),
          ),
          // My location FAB
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: AppColors.white,
              onPressed: _goToMyLocation,
              child: const Icon(
                Icons.my_location_rounded,
                color: AppColors.rose,
              ),
            ),
          ),
          // Legend
          Positioned(
            bottom: 24,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendItem('🔴', 'Donors'),
                  const SizedBox(height: 4),
                  _legendItem('🔵', 'Blood Banks'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterToggle(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.rose : AppColors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _legendItem(String icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(icon, style: const TextStyle(fontSize: 12)),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textBody,
        ),
      ),
    ],
  );

  Future<void> _zoomToUserLocation() async {
  try {
    final ctrl = await _mapController.future;
    // try GPS first
    final pos = await LocationService.getCurrentPosition();
    if (pos != null && mounted) {
      ctrl.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(pos.latitude, pos.longitude), 12,
      ));
      return;
    }
    // fallback — use saved lat/lng from AuthState profile if GPS fails
    // just stay at India view
  } catch (_) {}
}

Future<void> _goToMyLocation() async {
  _zoomToUserLocation();
}
}
