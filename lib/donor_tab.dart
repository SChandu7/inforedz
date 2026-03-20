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
  final String name, bloodGroup, city, gender, lastDonated, email, phone;
  final int age, weight, donations;
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
    required this.phone,
    required this.age,
    required this.weight,
    required this.donations,
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
    phone: j['phone'] ?? '',
    age: j['age'] ?? 0,
    weight: j['weight'] ?? 0,
    donations: j['donation_count'] ?? 0,
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
  bool _initialLoadDone = false;
  String _selectedGroup = 'All';
  bool _showOnlyAvailable = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollCtrl = ScrollController();
  final _types = ['All', 'O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];
  Timer? _debounce;

  // marquee scroll controller
  late ScrollController _marqueeCtrl;
  Timer? _marqueeTimer;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _marqueeCtrl = ScrollController();
    _loadDonors();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startMarquee());
    _searchFocus.addListener(() {
      if (_searchFocus.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollCtrl.animateTo(
            300, // approx position of search bar below hero + quick cards
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
          );
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialLoadDone) _silentRefresh();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    _marqueeTimer?.cancel();
    _marqueeCtrl.dispose();
    _searchFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _startMarquee() {
    _marqueeTimer = Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!_marqueeCtrl.hasClients) return;
      final max = _marqueeCtrl.position.maxScrollExtent;
      if (_marqueeCtrl.offset >= max) {
        _marqueeCtrl.jumpTo(0);
      } else {
        _marqueeCtrl.animateTo(
          _marqueeCtrl.offset + 1.2,
          duration: const Duration(milliseconds: 30),
          curve: Curves.linear,
        );
      }
    });
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
          _initialLoadDone = true;
          _applyFilter();
        });
      }
    } catch (e) {
      debugPrint('❌ loadDonors: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

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
        final updatedMap = {for (final d in list) d.id: d};
        setState(() {
          _allDonors = _allDonors.map((d) => updatedMap[d.id] ?? d).toList();
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
        final matchGroup =
            _selectedGroup == 'All' || d.bloodGroup == _selectedGroup;
        final matchAvailable = !_showOnlyAvailable || d.available;
        final matchSearch =
            q.isEmpty ||
            d.name.toLowerCase().contains(q) ||
            d.city.toLowerCase().contains(q) ||
            d.bloodGroup.toLowerCase().contains(q);
        return matchGroup && matchAvailable && matchSearch;
      }).toList();
    });
  }

  // ── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: _buildAppBar(),
      floatingActionButton: _buildMapFAB(),
      resizeToAvoidBottomInset: true,
      body: RefreshIndicator(
        color: AppColors.rose,
        onRefresh: _loadDonors,
        child: CustomScrollView(
          controller: _scrollCtrl, // ← add controller
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag, // ← dismiss on scroll
          slivers: [
            SliverToBoxAdapter(child: _buildMarqueeBanner()),
            SliverToBoxAdapter(child: _buildHeroStats()),

            SliverToBoxAdapter(
              child: _buildSectionHeader(
                '🩸 Find a Donor',
                'Browse all registered donors',
              ),
            ),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildFilterChips()),
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.rose),
                ),
              )
            else if (_filtered.isEmpty)
              SliverFillRemaining(child: _buildEmpty())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _DonorCard(donor: _filtered[i]),
                    childCount: _filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── APP BAR ────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.rose, width: 2),
            image: const DecorationImage(
              image: AssetImage('assets/icon.jpeg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      title: Center(
        child: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Info',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.inkDark,
                  fontFamily: 'Poppins',
                ),
              ),
              TextSpan(
                text: 'REDZ',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppColors.rose,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, color: AppColors.inkDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          onSelected: (val) => _handleMenu(val),
          itemBuilder: (_) => [
            _menuItem('about', Icons.info_outline_rounded, 'About InfoREDZ'),
            _menuItem('how', Icons.help_outline_rounded, 'How it works'),
            _menuItem(
              'eligibility',
              Icons.checklist_rounded,
              'Donation eligibility',
            ),
            _menuItem('support', Icons.headset_mic_outlined, 'Help & Support'),
            _menuItem('share', Icons.share_outlined, 'Share app'),
            _menuItem('privacy', Icons.privacy_tip_outlined, 'Privacy policy'),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.divider),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String val, IconData icon, String label) {
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.rose),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textBody),
          ),
        ],
      ),
    );
  }

  void _handleMenu(String val) {
    switch (val) {
      case 'about':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              backgroundColor: AppColors.bgPage,
              appBar: AppBar(
                backgroundColor: AppColors.white,
                elevation: 0,
                iconTheme: const IconThemeData(color: AppColors.inkDark),
                title: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Info',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.inkDark,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      TextSpan(
                        text: 'REDZ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.rose,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(height: 1, color: AppColors.divider),
                ),
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildGuestAboutPage(),
              ),
            ),
          ),
        );
        break;
      case 'how':
        _showInfoDialog(
          'How it works',
          '1. Register as a donor with your blood group & location.\n2. Toggle availability when you are ready to donate.\n3. Seekers find you on the map or donor list.\n4. They call or WhatsApp you directly.\n5. You save a life. 🩸',
        );
        break;
      case 'eligibility':
        _showInfoDialog(
          'Donation Eligibility',
          '✓ Age: 18–65 years\n✓ Weight: ≥ 45 kg\n✓ Haemoglobin: ≥ 12.5 g/dL\n✓ Gap between donations: 3 months\n✗ Not eligible if: pregnant, on medication, recent surgery, or chronic illness.',
        );
        break;
      case 'support':
        _showSupport();
        break;
      case 'share':
        launchUrl(
          Uri.parse(
            'https://play.google.com/store/apps/details?id=com.inforedz.app',
          ),
          mode: LaunchMode.externalApplication,
        );
        break;
      case 'privacy':
        launchUrl(
          Uri.parse('https://schandu7.github.io/infumedz/'),
          mode: LaunchMode.externalApplication,
        );
        break;
    }
  }

  Widget _buildGuestAboutPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── About card ──────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.rosePale,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.water_drop_rounded,
                      color: AppColors.rose,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'About InfoREDZ',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.inkDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Inforedz is India\'s free real-time blood donation platform — connecting donors, patients in need, and blood banks across the country. Our mission is simple: no life should be lost due to lack of blood.\n\n'
                'We built Inforedz to bridge the gap between those who can donate and those who urgently need blood. Whether it\'s a scheduled donation or an emergency SOS, Inforedz connects the right people at the right time.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textBody,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),

        // ── Stats ───────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _aboutStat('2800+', 'Donors', Icons.people_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _aboutStat(
                '120+',
                'Blood Banks',
                Icons.local_hospital_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _aboutStat('12K+', 'Lives Saved', Icons.favorite_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Mission ─────────────────────────────────────────
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🎯 Our Mission',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkDark,
                ),
              ),
              const SizedBox(height: 10),
              _missionPoint(
                Icons.volunteer_activism_rounded,
                'Make blood donation accessible to everyone in India',
              ),
              _missionPoint(
                Icons.map_rounded,
                'Real-time map showing donors and blood banks near you',
              ),
              _missionPoint(
                Icons.speed_rounded,
                'Connect seekers to donors in under 60 seconds',
              ),
              _missionPoint(
                Icons.lock_outlined,
                'Privacy-first — your data is never sold',
              ),
            ],
          ),
        ),

        // ── Team ────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            '👥 Meet the Team',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.inkDark,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            _teamCard(
              'assets/team1.jpg',

              'Dr.  Akif Baig',
              'CEO & Content Head',
              'MBBS, DNB (Gen Med), DM (Cardiology)',
              AppColors.rose,
            ),
            _teamCard(
              'assets/team2.jpg',

              'DR. M. A. Sameena Farheen',
              'Founder & Editor',
              'MBBS ,MD(Gen Med)',
              const Color(0xFF1565C0),
            ),
            _teamCard(
              'assets/team3.jpeg',

              'Nihal Baig',
              'Co Founder & CTO',
              'Btech & Mtech(IITB), Software Engineer',

              const Color(0xFF1565C0),
            ),
            _teamCard(
              'assets/team4.jpeg',

              '4th member Detials here ',
              'Founder & Editor',
              'MBBS ,MD(Gen Med)',
              const Color(0xFF1565C0),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Join CTA ─────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.rose, AppColors.roseDark],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                'Ready to save a life?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Register as a donor or blood bank today',
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.rose,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Create Free Account',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Footer ───────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard2 ?? AppColors.bgPage,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Info',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.inkDark,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    TextSpan(
                      text: 'REDZ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.rose,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Every drop counts. Every life matters.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _footerLink(
                    'Privacy Policy',
                    () => launchUrl(
                      Uri.parse('https://schandu7.github.io/infumedz/'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  const Text(
                    ' · ',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  _footerLink('Terms of Use', () => _showTerms()),
                  const Text(
                    ' · ',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  _footerLink('Support', () => _showSupport()),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '© 2026 InfoREDZ. All rights reserved.\nMade with ❤️ in India',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  void _showTerms() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: AppColors.bgPage,
          appBar: AppBar(
            backgroundColor: AppColors.rose,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            centerTitle: true,
            title: const Text(
              'Terms & Conditions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.rosePale,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.rose.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.gavel_rounded,
                        color: AppColors.rose,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'INFOREDZ – TERMS AND CONDITIONS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.roseDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ..._termsList().map(
                  (t) => _termItem(t['num']!, t['title']!, t['body']!),
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.rosePale,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'By using Inforedz, you acknowledge that you have read, understood, and agree to these Terms and Conditions.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.inkMid,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Map<String, String>> _termsList() => [
    {
      'num': '1',
      'title': 'Nature of Service',
      'body':
          'Inforedz is a digital platform that facilitates connection between blood donors, blood banks, and recipients. It does not collect, store, or supply blood and is not a medical service provider.',
    },
    {
      'num': '2',
      'title': 'User Responsibilities',
      'body':
          'All users must provide accurate and complete information and use the platform only for lawful and genuine purposes. Misuse may result in suspension or termination of access.',
    },
    {
      'num': '3',
      'title': 'Blood Donors',
      'body':
          'Donors must be medically eligible, provide truthful health information, and participate voluntarily without any financial compensation. Donors consent to being contacted for donation requests.',
    },
    {
      'num': '4',
      'title': 'Blood Banks',
      'body':
          'Blood banks must be duly authorized as per applicable local regulations and are solely responsible for safe collection, testing, storage, and distribution of blood, as well as maintaining accurate records.',
    },
    {
      'num': '5',
      'title': 'Recipients / Customers',
      'body':
          'Users requesting blood must provide accurate details and use the platform strictly for legitimate medical needs. All procedures and transactions are subject to the policies of the respective blood banks or healthcare providers.',
    },
    {
      'num': '6',
      'title': 'Payments',
      'body':
          'Any charges related to blood or services are determined and collected by blood banks or healthcare providers. Inforedz holds no responsibility for pricing or transactions.',
    },
    {
      'num': '7',
      'title': 'Data Privacy',
      'body':
          'Inforedz maintains reasonable measures to protect user data. Information may be shared with relevant parties only for facilitating services.',
    },
    {
      'num': '8',
      'title': 'Disclaimer of Liability',
      'body':
          'Inforedz does not guarantee availability of blood or donors and shall not be held liable for any medical outcomes, delays, or actions of third parties.',
    },
    {
      'num': '9',
      'title': 'Account Control',
      'body':
          'Inforedz reserves the right to suspend or terminate accounts in case of false information, misuse, or violation of these terms.',
    },
    {
      'num': '10',
      'title': 'Acceptance',
      'body':
          'Continued use of the platform constitutes acceptance of these Terms and Conditions.',
    },
  ];

  Widget _termItem(String num, String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.rose,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              num,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textBody,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  void _showSupport() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
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
                Icons.headset_mic_rounded,
                color: AppColors.rose,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.inkDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Reach us through any channel below',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),

            // Call
            _supportBtn(
              icon: Icons.call_rounded,
              label: 'Call Support',
              sub: '+91 93817 40718',
              color: AppColors.rose,
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri(scheme: 'tel', path: '+919381740718');
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
            const SizedBox(height: 12),

            // WhatsApp
            _supportBtn(
              icon: Icons.chat_rounded,
              label: 'WhatsApp Support',
              sub: 'Chat with us on WhatsApp',
              color: const Color(0xFF25D366),
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri.parse(
                  'https://wa.me/919381740718?text=Hi%20Inforedz%20Support%2C%20I%20need%20help',
                );
                if (await canLaunchUrl(uri))
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
            ),
            const SizedBox(height: 12),

            // Email
            _supportBtn(
              icon: Icons.email_rounded,
              label: 'Email Support',
              sub: 'infusionmedzone@gmail.com',
              color: const Color(0xFF1565C0),
              onTap: () async {
                Navigator.pop(context);
                final uri = Uri(
                  scheme: 'mailto',
                  path: 'infusionmedzone@gmail.com',
                  query: 'subject=Inforedz Support Request',
                );
                if (await canLaunchUrl(uri)) await launchUrl(uri);
              },
            ),
            const SizedBox(height: 12),

            // Cancel
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

  Widget _supportBtn({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    sub,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: color.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _aboutStat(String val, String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: AppColors.rosePale,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        Icon(icon, size: 18, color: AppColors.rose),
        const SizedBox(height: 6),
        Text(
          val,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.rose,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.inkLight),
        ),
      ],
    ),
  );

  Widget _missionPoint(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.rose),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textBody,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _teamCard(
    String imagePath,
    String name,
    String role,
    String desc,
    Color color,
  ) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.cardWhite,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.divider, width: 0.5),
      boxShadow: [
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.4), width: 2),
          ),
          child: ClipOval(
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: color.withOpacity(0.12),
                child: Icon(Icons.person_rounded, color: color, size: 26),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.inkDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          role,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
            height: 1.4,
          ),
        ),
      ],
    ),
  );

  Widget _footerLink(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.rose,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  void _showInfoDialog(String title, String content) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.rosePale,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.water_drop_rounded,
                    color: AppColors.rose,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textBody,
                height: 1.7,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── MARQUEE BANNER ─────────────────────────────────────────
  Widget _buildMarqueeBanner() {
    const text =
        '🩸 Every drop counts — Register as a donor today   •   '
        '🏥 Find blood banks near you on the map   •   '
        '❤️ Over 12,000 lives saved through Inforedz   •   '
        '🆘 Emergency? Post a request or call a donor now   •   '
        '✅ 100% Free — No fees, no ads, no barriers   •   '
        '📍 Enable location to appear on the donor map   •   ';

    return Container(
      color: AppColors.roseDark,
      height: 32,
      child: SingleChildScrollView(
        controller: _marqueeCtrl,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            // repeat text 3x so loop is seamless
            for (int i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── HERO STATS ─────────────────────────────────────────────
  Widget _buildHeroStats() {
    final total = _allDonors.length;
    final available = _allDonors.where((d) => d.available).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.rose, AppColors.roseDark],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.rose.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${AuthState.name?.split(' ').first ?? 'Friend'} 👋',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Ready to save a life today?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.volunteer_activism_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AuthState.role == 'donor' ? 'Donor' : 'Blood Bank',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _heroStat(
                  '$total',
                  'Total Donors',
                  Icons.people_rounded,
                ),
              ),
              _heroDivider(),
              Expanded(
                child: _heroStat(
                  '$available',
                  'Available Now',
                  Icons.check_circle_rounded,
                ),
              ),
              _heroDivider(),
              const Expanded(
                child: _heroStatStatic(
                  '12K+',
                  'Lives Saved',
                  Icons.favorite_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String val, String label, IconData icon) => Column(
    children: [
      Icon(icon, size: 14, color: Colors.white70),
      const SizedBox(height: 4),
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
        style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.8)),
      ),
    ],
  );

  Widget _heroDivider() =>
      Container(width: 1, height: 40, color: Colors.white.withOpacity(0.25));

  // ── QUICK INFO CARDS ───────────────────────────────────────

  Widget _infoCard(
    String emoji,
    String title,
    String sub,
    Color bg,
    Color accent,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: TextStyle(fontSize: 9, color: accent.withOpacity(0.7)),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  // ── SECTION HEADER ─────────────────────────────────────────
  Widget _buildSectionHeader(String title, String sub) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.inkDark,
            ),
          ),
          Text(
            sub,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ── SEARCH ─────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocus, // ← attach focus node

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

  // ── FILTER CHIPS ───────────────────────────────────────────
  Widget _buildFilterChips() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        children: [
          ..._types.map((t) {
            final sel = t == _selectedGroup;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedGroup = t);
                _applyFilter();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: sel ? AppColors.rose : AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel ? AppColors.rose : AppColors.divider,
                  ),
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: AppColors.rose.withOpacity(0.25),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  t,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            );
          }),
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.only(right: 8, top: 4),
            color: AppColors.divider,
          ),
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
                border: Border.all(
                  color: _showOnlyAvailable
                      ? AppColors.success
                      : AppColors.divider,
                ),
                boxShadow: _showOnlyAvailable
                    ? [
                        BoxShadow(
                          color: AppColors.success.withOpacity(0.25),
                          blurRadius: 8,
                        ),
                      ]
                    : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _showOnlyAvailable
                          ? Colors.white
                          : AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Available',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _showOnlyAvailable
                          ? Colors.white
                          : AppColors.success,
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

  // ── MAP FAB ────────────────────────────────────────────────
  Widget _buildMapFAB() {
    return FloatingActionButton.extended(
      heroTag: 'donor_map_fab',
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

// ─────────────────────────────────────────────────────────────
// HERO STAT STATIC
// ─────────────────────────────────────────────────────────────
class _heroStatStatic extends StatelessWidget {
  final String val, label;
  final IconData icon;
  const _heroStatStatic(this.val, this.label, this.icon);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, size: 14, color: Colors.white70),
      const SizedBox(height: 4),
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
        style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.8)),
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
      _snack(context, 'No phone number available');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
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
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
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

  void _openWhatsApp(BuildContext context, String phone) async {
    if (phone.isEmpty) {
      _snack(context, 'No phone number available');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
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
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat, color: Colors.green, size: 26),
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
                  String cleaned = phone.replaceAll(
                    RegExp(r'[\s\-\(\)\+]'),
                    '',
                  );
                  if (!cleaned.startsWith('91') && cleaned.length == 10)
                    cleaned = '91$cleaned';
                  final uri = Uri.parse('https://wa.me/$cleaned');
                  if (await canLaunchUrl(uri))
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  else if (context.mounted)
                    _snack(context, 'WhatsApp not installed');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.chat, color: Colors.white),
                label: const Text(
                  'Chat on WhatsApp',
                  style: TextStyle(
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

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
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
                  () => _callDonor(ctx, donor.phone),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Builder(
              builder: (ctx) => Expanded(
                child: _actionBtn(
                  Icons.chat_bubble_outline_rounded,
                  'WhatsApp',
                  AppColors.success,
                  true,
                  () => _openWhatsApp(ctx, donor.phone),
                ),
              ),
            ),
          ],
        ),
      ],
    );
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
// DONOR MAP SCREEN
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
      if (!mounted) return;
      if (dRes['success'] == true)
        _donorData = List<Map<String, dynamic>>.from(dRes['data']);
      if (bRes['success'] == true)
        _bankData = List<Map<String, dynamic>>.from(bRes['data']);
    } catch (_) {}
    if (!mounted) return;
    _buildMarkers();
    setState(() => _loading = false);
  }

  void _buildMarkers() {
    final markers = <Marker>{};
    if (_showDonors) {
      for (final d in _donorData) {
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
              snippet: d['city'] ?? '',
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
    if (!mounted) return;
    setState(() => _markers = markers);
  }

  Future<void> _zoomToUserLocation() async {
    try {
      final ctrl = await _mapController.future;
      final pos = await LocationService.getCurrentPosition();
      if (pos != null && mounted) {
        ctrl.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 12),
        );
      }
    } catch (_) {}
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
                    _zoomToUserLocation();
                  },
                ),
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
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'location_fab',
              mini: true,
              backgroundColor: AppColors.white,
              onPressed: _zoomToUserLocation,
              child: const Icon(
                Icons.my_location_rounded,
                color: AppColors.rose,
              ),
            ),
          ),
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

  Widget _filterToggle(String label, bool active, VoidCallback onTap) =>
      GestureDetector(
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
}
