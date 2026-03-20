import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────
// PROFILE TAB — unified for both donor & blood bank roles
// ─────────────────────────────────────────────────────────────
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});
  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic> _profile = {};
  bool _loading = true;
  bool _isSaving = false;

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

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get(
        '/profile/',
        params: {'user_id': '${AuthState.userId}'},
      );
      if (res['success'] == true) {
        final raw = res['data'];
        // handle both {data: {...}} and {data: {user: {...}}} shapes
        if (raw is Map && raw.containsKey('user')) {
          setState(() => _profile = Map<String, dynamic>.from(raw['user']));
        } else {
          setState(() => _profile = Map<String, dynamic>.from(raw));
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.inkDark,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await AuthState.clear();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (_) => false,
        );
      }
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
                      text: 'redz',
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgPage,
        body: Center(child: CircularProgressIndicator(color: AppColors.rose)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AuthState.isGuest
                  ? _buildGuestAboutPage()
                  : AuthState.role == 'blood_bank'
                  ? _buildBankProfile()
                  : _buildDonorProfile(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverHeader() {
    final isDonor = AuthState.role == 'donor';
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: AppColors.rose,
      actions: [
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white),
          onPressed: _logout,
          tooltip: 'Sign Out',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.rose, AppColors.roseDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _initials(AuthState.name ?? ''),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AuthState.isGuest
                                  ? 'About InfoREDZ'
                                  : (AuthState.name ?? 'User'),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isDonor
                                        ? Icons.volunteer_activism_rounded
                                        : Icons.local_hospital_rounded,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isDonor ? 'Blood Donor' : 'Blood Bank',
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
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── DONOR PROFILE ──────────────────────────────────────────
  Widget _buildDonorProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDonorStats(),
        const SizedBox(height: 16),
        _buildAvailabilityCard(),
        const SizedBox(height: 16),
        _buildDonorEditCard(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildDonorStats() {
    final donations = _profile['donation_count'] ?? 0;
    final blood = AuthState.bloodGroup ?? _profile['blood_group'] ?? '--';
    return Row(
      children: [
        Expanded(
          child: _statCard('$donations', 'Donations', Icons.water_drop_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(blood, 'Blood Group', Icons.bloodtype_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            _profile['city'] ?? '--',
            'City',
            Icons.location_on_rounded,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String val, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
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
        children: [
          Icon(icon, size: 18, color: AppColors.rose),
          const SizedBox(height: 6),
          Text(
            val,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.inkDark,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    final isAvailable = _profile['is_available'] ?? false;
    return AppCard(
      borderColor: isAvailable ? AppColors.rose.withOpacity(0.3) : null,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isAvailable ? AppColors.rosePale : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.volunteer_activism_rounded,
              color: isAvailable ? AppColors.rose : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Donation Availability',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkDark,
                  ),
                ),
                Text(
                  isAvailable
                      ? 'You are visible to donors and on the map'
                      : 'You are hidden from the donor list and map',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isAvailable,
            activeColor: AppColors.rose,
            onChanged: (val) => _toggleAvailability(val),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAvailability(bool val) async {
    // optimistic update
    setState(() => _profile['is_available'] = val);

    final res = await ApiService.patch('/profile/', {
      'user_id': AuthState.userId,
      'is_available': val,
    });

    if (!mounted) return;

    if (res['success'] == true) {
      // update local profile from server response
      final updated = res['data'];
      if (updated != null) {
        setState(
          () => _profile['is_available'] = updated['is_available'] ?? val,
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            val
                ? '✓ You are now visible to seekers'
                : '✓ You are now hidden from the list',
          ),
          backgroundColor: val ? AppColors.success : AppColors.inkMid,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      // revert on failure
      setState(() => _profile['is_available'] = !val);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Failed to update availability'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildDonorEditCard() {
    return _EditDonorCard(
      profile: _profile,
      onSaved: (updated) async {
        setState(() => _isSaving = true);
        final payload = {'user_id': AuthState.userId, ...updated};
        final res = await ApiService.patch('/profile/', payload);
        if (res['success'] == true) {
          setState(() => _profile = Map<String, dynamic>.from(res['data']));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated!'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        }
        setState(() => _isSaving = false);
      },
      isSaving: _isSaving,
    );
  }

  // ── BLOOD BANK PROFILE ────────────────────────────────────
  Widget _buildBankProfile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBankStatusCard(),
        const SizedBox(height: 16),
        _buildStockEditor(),
        const SizedBox(height: 16),
        _buildBankEditCard(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildBankStatusCard() {
    final isOpen = _profile['is_open'] ?? false;
    return AppCard(
      borderColor: isOpen ? AppColors.rose.withOpacity(0.3) : null,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isOpen ? AppColors.rosePale : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_hospital_rounded,
              color: isOpen ? AppColors.rose : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bank Status',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.inkDark,
                  ),
                ),
                Text(
                  isOpen
                      ? 'Open — visible on map & list'
                      : 'Closed — hidden from public',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: isOpen,
            activeColor: AppColors.rose,
            onChanged: (val) async {
              // optimistic update
              setState(() => _profile['is_open'] = val);

              final res = await ApiService.patch('/profile/', {
                'user_id': AuthState.userId, // ← was missing
                'is_open': val,
              });

              if (!mounted) return;

              if (res['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      val ? '✓ Bank is now Open' : '✓ Bank is now Closed',
                    ),
                    backgroundColor: val ? AppColors.success : AppColors.inkMid,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else {
                // revert on failure
                setState(() => _profile['is_open'] = !val);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(res['message'] ?? 'Failed to update status'),
                    backgroundColor: AppColors.danger,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStockEditor() {
    const groups = ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];
    final stock = Map<String, dynamic>.from(_profile['stock'] ?? {});
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.water_drop_rounded,
                size: 16,
                color: AppColors.rose,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Update Blood Stock',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _saveStock(stock),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.rose,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Enter number of units available per blood group:',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 3.5,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: groups.map((g) {
              final ctrl = TextEditingController(text: '${stock[g] ?? 0}');
              return Row(
                children: [
                  Container(
                    width: 42,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.rosePale,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(8),
                      ),
                      border: const Border.fromBorderSide(
                        BorderSide(color: AppColors.divider),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        g,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.rose,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: ctrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textBody,
                      ),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(8),
                          ),
                          borderSide: BorderSide(color: AppColors.divider),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(8),
                          ),
                          borderSide: BorderSide(color: AppColors.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.horizontal(
                            right: Radius.circular(8),
                          ),
                          borderSide: BorderSide(
                            color: AppColors.rose,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: AppColors.offWhite,
                      ),
                      onChanged: (v) => stock[g] = int.tryParse(v) ?? 0,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _saveStock(Map<String, dynamic> stock) async {
    setState(() => _isSaving = true);
    final res = await ApiService.patch('/profile/', {
      'user_id': AuthState.userId, // ← was missing
      'stock': stock,
    });
    if (mounted) {
      if (res['success'] == true) {
        // update local profile stock so UI reflects immediately
        setState(() {
          _profile['stock'] = stock;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Stock updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Failed to update stock'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildBankEditCard() {
    return _EditBankCard(
      profile: _profile,
      onSaved: (updated) async {
        setState(() => _isSaving = true);
        final payload = {'user_id': AuthState.userId, ...updated};
        final res = await ApiService.patch('/profile/', payload);
        if (res['success'] == true) {
          setState(() => _profile = Map<String, dynamic>.from(res['data']));
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Details updated!'),
                backgroundColor: AppColors.success,
              ),
            );
        }
        setState(() => _isSaving = false);
      },
      isSaving: _isSaving,
    );
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

// ─────────────────────────────────────────────────────────────
// EDIT DONOR CARD
// ─────────────────────────────────────────────────────────────
class _EditDonorCard extends StatefulWidget {
  final Map<String, dynamic> profile;
  final Function(Map<String, dynamic>) onSaved;
  final bool isSaving;
  const _EditDonorCard({
    required this.profile,
    required this.onSaved,
    required this.isSaving,
  });
  @override
  State<_EditDonorCard> createState() => _EditDonorCardState();
}

class _EditDonorCardState extends State<_EditDonorCard> {
  bool _expanded = false;
  late TextEditingController _nameCtrl, _cityCtrl, _ageCtrl, _weightCtrl;
  late String _gender, _bloodGroup;
  DateTime? _lastDonatedDate;
  bool _hasCondition = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p['name'] ?? AuthState.name ?? '');
    _cityCtrl = TextEditingController(text: p['city'] ?? '');
    _ageCtrl = TextEditingController(text: '${p['age'] ?? ''}');
    _weightCtrl = TextEditingController(text: '${p['weight'] ?? ''}');
    _gender = p['gender'] ?? 'Male';
    _bloodGroup = p['blood_group'] ?? AuthState.bloodGroup ?? 'O+';
    final raw = p['last_donated'] ?? '';
    _lastDonatedDate = raw.isNotEmpty ? DateTime.tryParse(raw) : null;
    _hasCondition = p['has_condition'] ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
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
                final uri = Uri.parse(
                  'mailto:infusionmedzone@gmail.com?subject=Inforedz%20Support%20Request',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else {
                  // fallback — copy email to clipboard
                  await Clipboard.setData(
                    const ClipboardData(text: 'infusionmedzone@gmail.com'),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'No email app found — email copied to clipboard',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              GestureDetector(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: AppColors.rose,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Edit Donor Profile',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.inkDark,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppColors.rose,
                      ),
                    ],
                  ),
                ),
              ),
              if (_expanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      const Divider(color: AppColors.divider, height: 1),
                      const SizedBox(height: 14),
                      _field(_nameCtrl, 'Full Name', Icons.person_outline),
                      const SizedBox(height: 12),
                      _field(_cityCtrl, 'City', Icons.location_city_outlined),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _ageCtrl,
                              'Age',
                              Icons.cake_outlined,
                              type: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _field(
                              _weightCtrl,
                              'Weight (kg)',
                              Icons.monitor_weight_outlined,
                              type: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _bloodGroupDrop(),
                      const SizedBox(height: 12),
                      _lastDonatedDrop(),
                      const SizedBox(height: 12),
                      _conditionRow(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: widget.isSaving ? null : _save,
                          child: widget.isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Footer outside AppCard ────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard2,
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
                      text: 'redz',
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
                  _link('Privacy Policy'),
                  const Text(
                    ' · ',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  _link('Terms of Use'),
                  const Text(
                    ' · ',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                  _link('Support'),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                '© 2025 InfoREDZ. All rights reserved.\nMade with ❤️ in India',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        //    const SizedBox(height: 10),
      ],
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? type,
  }) {
    return TextField(
      controller: c,
      keyboardType: type,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }

  Widget _link(String label) => GestureDetector(
    onTap: () => _handleFooterLink(label),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.rose,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  void _handleFooterLink(String label) {
    switch (label) {
      case 'Privacy Policy':
        launchUrl(
          Uri.parse('https://schandu7.github.io/infumedz/'),
          mode: LaunchMode.externalApplication,
        );
        break;
      case 'Terms of Use':
        _showTerms();
        break;
      case 'Support':
        _showSupport();
        break;
    }
  }

  Widget _bloodGroupDrop() {
    const groups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];
    return DropdownButtonFormField<String>(
      value: _bloodGroup,
      decoration: const InputDecoration(
        labelText: 'Blood Group',
        prefixIcon: Icon(Icons.water_drop_outlined, size: 18),
      ),
      items: groups
          .map((g) => DropdownMenuItem(value: g, child: Text(g)))
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _bloodGroup = v);
      },
    );
  }

  Widget _lastDonatedDrop() {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _lastDonatedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.rose,
                onPrimary: Colors.white,
                onSurface: AppColors.inkDark,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() => _lastDonatedDate = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _lastDonatedDate != null
                ? AppColors.rose
                : AppColors.divider,
            width: _lastDonatedDate != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month_rounded,
              size: 18,
              color: _lastDonatedDate != null
                  ? AppColors.rose
                  : AppColors.inkLight,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _lastDonatedDate != null
                    ? 'Last donated: ${_fmtDate(_lastDonatedDate!)}'
                    : 'Last donation date (tap to select)',
                style: TextStyle(
                  fontSize: 13,
                  color: _lastDonatedDate != null
                      ? AppColors.textBody
                      : AppColors.textMuted,
                ),
              ),
            ),
            if (_lastDonatedDate != null)
              GestureDetector(
                onTap: () => setState(() => _lastDonatedDate = null),
                child: const Icon(
                  Icons.clear_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Widget _conditionRow() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.offWhite,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.divider),
    ),
    child: Row(
      children: [
        const Expanded(
          child: Text(
            'Chronic medical condition',
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

  void _save() {
    widget.onSaved({
      'name': _nameCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'age': int.tryParse(_ageCtrl.text) ?? 0,
      'weight': int.tryParse(_weightCtrl.text) ?? 0,
      'gender': _gender,
      'blood_group': _bloodGroup,
      'last_donated': _lastDonatedDate != null
          ? _lastDonatedDate!.toIso8601String().split('T')[0]
          : '',
      'has_condition': _hasCondition,
    });
  }
}

// ─────────────────────────────────────────────────────────────
// EDIT BANK CARD
// ─────────────────────────────────────────────────────────────
class _EditBankCard extends StatefulWidget {
  final Map<String, dynamic> profile;
  final Function(Map<String, dynamic>) onSaved;
  final bool isSaving;
  const _EditBankCard({
    required this.profile,
    required this.onSaved,
    required this.isSaving,
  });
  @override
  State<_EditBankCard> createState() => _EditBankCardState();
}

class _EditBankCardState extends State<_EditBankCard> {
  bool _expanded = false;
  late TextEditingController _bankNameCtrl,
      _addressCtrl,
      _phoneCtrl,
      _cityCtrl,
      _timingCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _bankNameCtrl = TextEditingController(
      text: p['bank_name'] ?? AuthState.bankName ?? '',
    );
    _addressCtrl = TextEditingController(text: p['bank_address'] ?? '');
    _phoneCtrl = TextEditingController(text: p['bank_phone'] ?? '');
    _cityCtrl = TextEditingController(text: p['city'] ?? '');
    _timingCtrl = TextEditingController(text: p['timing'] ?? '');
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _timingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.edit_rounded,
                    size: 16,
                    color: AppColors.rose,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Edit Bank Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkDark,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.rose,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(color: AppColors.divider, height: 1),
                  const SizedBox(height: 14),
                  _field(
                    _bankNameCtrl,
                    'Bank / Organisation Name',
                    Icons.business_outlined,
                  ),
                  const SizedBox(height: 12),
                  _field(_cityCtrl, 'City', Icons.location_city_outlined),
                  const SizedBox(height: 12),
                  _field(
                    _addressCtrl,
                    'Full Address',
                    Icons.location_on_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _phoneCtrl,
                    'Contact Phone',
                    Icons.phone_outlined,
                    type: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    _timingCtrl,
                    'Operating Hours (e.g. 9AM–8PM)',
                    Icons.access_time_rounded,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: widget.isSaving ? null : _save,
                      child: widget.isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label,
    IconData icon, {
    TextInputType? type,
    int maxLines = 1,
  }) {
    return TextField(
      controller: c,
      keyboardType: type,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
      ),
    );
  }

  void _save() {
    widget.onSaved({
      'bank_name': _bankNameCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'bank_address': _addressCtrl.text.trim(),
      'bank_phone': _phoneCtrl.text.trim(),
      'timing': _timingCtrl.text.trim(),
    });
  }
}
