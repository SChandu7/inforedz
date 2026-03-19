import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const BloodBridgeApp());
}

// ─── Theme ───────────────────────────────────────────────────────────────────

class AppColors {
  static const crimson = Color(0xFFCC0000);
  static const crimsonDark = Color(0xFF8B0000);
  static const crimsonLight = Color(0xFFFF3333);
  static const bgDark = Color(0xFF0D0D0D);
  static const bgCard = Color(0xFF1A1A1A);
  static const bgCard2 = Color(0xFF222222);
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFBBBBBB);
  static const textMuted = Color(0xFF777777);
  static const success = Color(0xFF2ECC71);
  static const warning = Color(0xFFF39C12);
  static const urgent = Color(0xFFFF4444);
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class Donor {
  final String name, blood, city, phone, avatar, lastDonated;
  final bool available;
  final int donations;
  const Donor({
    required this.name,
    required this.blood,
    required this.city,
    required this.phone,
    required this.avatar,
    required this.lastDonated,
    required this.available,
    required this.donations,
  });
}

class BloodRequest {
  final String patient, blood, hospital, city, units, postedTime, contact;
  final String urgency; // critical | urgent | normal
  const BloodRequest({
    required this.patient,
    required this.blood,
    required this.hospital,
    required this.city,
    required this.units,
    required this.postedTime,
    required this.contact,
    required this.urgency,
  });
}

class BloodBank {
  final String name, city, address, phone, timing;
  final Map<String, int> stock;
  final double rating;
  final bool open;
  const BloodBank({
    required this.name,
    required this.city,
    required this.address,
    required this.phone,
    required this.timing,
    required this.stock,
    required this.rating,
    required this.open,
  });
}

// ─── Sample Data ─────────────────────────────────────────────────────────────

final List<Donor> donors = [
  const Donor(name: 'Arjun Mehta', blood: 'O+', city: 'Delhi', phone: '+91 98100 11223', avatar: 'AM', lastDonated: '3 months ago', available: true, donations: 12),
  const Donor(name: 'Priya Sharma', blood: 'A-', city: 'Mumbai', phone: '+91 98200 44556', avatar: 'PS', lastDonated: '1 month ago', available: false, donations: 7),
  const Donor(name: 'Rohan Gupta', blood: 'B+', city: 'Bangalore', phone: '+91 91100 77889', avatar: 'RG', lastDonated: '5 months ago', available: true, donations: 20),
  const Donor(name: 'Sneha Patel', blood: 'AB+', city: 'Ahmedabad', phone: '+91 93300 22110', avatar: 'SP', lastDonated: '2 months ago', available: true, donations: 5),
  const Donor(name: 'Vikram Singh', blood: 'O-', city: 'Jaipur', phone: '+91 99900 33221', avatar: 'VS', lastDonated: '4 months ago', available: true, donations: 15),
  const Donor(name: 'Anita Nair', blood: 'A+', city: 'Chennai', phone: '+91 98400 55667', avatar: 'AN', lastDonated: '6 months ago', available: true, donations: 9),
];

final List<BloodRequest> requests = [
  const BloodRequest(patient: 'Ravi Kumar', blood: 'O-', hospital: 'AIIMS Delhi', city: 'New Delhi', units: '3 units', postedTime: '10 min ago', contact: '+91 98765 43210', urgency: 'critical'),
  const BloodRequest(patient: 'Meera Joshi', blood: 'B+', hospital: 'Fortis Hospital', city: 'Noida', units: '2 units', postedTime: '45 min ago', contact: '+91 98100 22334', urgency: 'urgent'),
  const BloodRequest(patient: 'Suresh Rao', blood: 'AB-', hospital: 'Apollo Hospitals', city: 'Hyderabad', units: '1 unit', postedTime: '2 hrs ago', contact: '+91 97600 55443', urgency: 'urgent'),
  const BloodRequest(patient: 'Fatima Sheikh', blood: 'A+', hospital: 'Lilavati Hospital', city: 'Mumbai', units: '4 units', postedTime: '3 hrs ago', contact: '+91 99800 11234', urgency: 'normal'),
  const BloodRequest(patient: 'Deepak Verma', blood: 'O+', hospital: 'Narayana Health', city: 'Bangalore', units: '2 units', postedTime: '5 hrs ago', contact: '+91 90000 66778', urgency: 'normal'),
];

final List<BloodBank> banks = [
  const BloodBank(name: 'LifeSource Blood Centre', city: 'New Delhi', address: 'Plot 12, Connaught Place, New Delhi', phone: '+91 11 2345 6789', timing: '24/7 Open', stock: {'O+': 45, 'O-': 12, 'A+': 38, 'A-': 8, 'B+': 30, 'B-': 6, 'AB+': 20, 'AB-': 4}, rating: 4.8, open: true),
  const BloodBank(name: 'RedCross Blood Bank', city: 'Mumbai', address: '14 Dr. DN Road, Fort, Mumbai', phone: '+91 22 6789 1234', timing: '8AM – 10PM', stock: {'O+': 60, 'O-': 5, 'A+': 42, 'A-': 15, 'B+': 25, 'B-': 10, 'AB+': 18, 'AB-': 2}, rating: 4.6, open: true),
  const BloodBank(name: 'Sanjeevani Blood Centre', city: 'Bangalore', address: '88 MG Road, Shivaji Nagar, Bangalore', phone: '+91 80 4567 8901', timing: '9AM – 8PM', stock: {'O+': 28, 'O-': 3, 'A+': 35, 'A-': 6, 'B+': 40, 'B-': 8, 'AB+': 12, 'AB-': 1}, rating: 4.3, open: false),
  const BloodBank(name: 'Apollo Blood Services', city: 'Chennai', address: '21 Greams Road, Thousand Lights, Chennai', phone: '+91 44 2345 9876', timing: '24/7 Open', stock: {'O+': 55, 'O-': 9, 'A+': 50, 'A-': 11, 'B+': 33, 'B-': 7, 'AB+': 22, 'AB-': 5}, rating: 4.9, open: true),
];

// ─── App Root ─────────────────────────────────────────────────────────────────

class BloodBridgeApp extends StatelessWidget {
  const BloodBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BloodBridge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.bgDark,
        primaryColor: AppColors.crimson,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.crimson,
          surface: AppColors.bgCard,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

// ─── Home Screen (3 tabs) ─────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  static const _pages = [DonorPage(), NeedBloodPage(), BloodBankPage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_tab],
      bottomNavigationBar: _buildNav(),
    );
  }

  Widget _buildNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.crimson.withOpacity(0.3), width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _navItem(0, Icons.volunteer_activism_rounded, 'Donate'),
              _navItem(1, Icons.bloodtype_rounded, 'Need Blood'),
              _navItem(2, Icons.local_hospital_rounded, 'Blood Banks'),
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
            Icon(icon, color: active ? AppColors.crimson : AppColors.textMuted, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? AppColors.crimson : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared Widgets ───────────────────────────────────────────────────────────

class PageHeader extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  const PageHeader({super.key, required this.title, required this.subtitle, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.crimsonDark, Color(0xFF1A0000)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.7))),
                ],
              ),
              const Spacer(),
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BloodTypeBadge extends StatelessWidget {
  final String type;
  final double size;
  const BloodTypeBadge({super.key, required this.type, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.6, vertical: size * 0.3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.crimson, AppColors.crimsonDark]),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(type, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }
}

class StockChip extends StatelessWidget {
  final String group;
  final int units;
  const StockChip({super.key, required this.group, required this.units});

  Color get _color {
    if (units == 0) return AppColors.textMuted;
    if (units < 5) return AppColors.urgent;
    if (units < 15) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(group, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 2),
          Text('$units', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _color)),
        ],
      ),
    );
  }
}

// ─── 1. Donor Page ────────────────────────────────────────────────────────────

class DonorPage extends StatefulWidget {
  const DonorPage({super.key});

  @override
  State<DonorPage> createState() => _DonorPageState();
}

class _DonorPageState extends State<DonorPage> {
  String _filter = 'All';
  final _types = ['All', 'O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-'];

  List<Donor> get _filtered =>
      _filter == 'All' ? donors : donors.where((d) => d.blood == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PageHeader(title: 'BloodBridge', subtitle: 'Find a donor near you', icon: Icons.volunteer_activism_rounded),
        _buildStats(),
        _buildSearch(),
        _buildFilters(),
        Expanded(child: _buildList()),
        _buildRegisterBtn(),
      ],
    );
  }

  Widget _buildStats() {
    return Container(
      color: AppColors.bgCard2,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _stat('2,841', 'Donors'),
          _divider(),
          _stat('6', 'Cities'),
          _divider(),
          _stat('12K+', 'Lives Saved'),
        ],
      ),
    );
  }

  Widget _stat(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.crimson)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 30, color: AppColors.bgCard);

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Container(
        decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12)),
        child: const TextField(
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search by name, city or blood type...',
            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _types.length,
        itemBuilder: (_, i) {
          final t = _types[i];
          final sel = t == _filter;
          return GestureDetector(
            onTap: () => setState(() => _filter = t),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: sel ? const LinearGradient(colors: [AppColors.crimson, AppColors.crimsonDark]) : null,
                color: sel ? null : AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: sel ? null : Border.all(color: AppColors.bgCard2),
              ),
              child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sel ? Colors.white : AppColors.textSecondary)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _DonorCard(donor: _filtered[i]),
    );
  }

  Widget _buildRegisterBtn() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.crimson,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.add_circle_outline, color: Colors.white),
          label: const Text('Register as a Donor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        ),
      ),
    );
  }
}

class _DonorCard extends StatelessWidget {
  final Donor donor;
  const _DonorCard({required this.donor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: donor.available ? AppColors.crimson.withOpacity(0.25) : Colors.transparent),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.crimson.withOpacity(0.2),
                child: Text(donor.avatar, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.crimson)),
              ),
              if (donor.available)
                Positioned(
                  right: 0, bottom: 0,
                  child: Container(
                    width: 12, height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bgCard, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(donor.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                    const Spacer(),
                    BloodTypeBadge(type: donor.blood),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 2),
                    Text(donor.city, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 12),
                    const Icon(Icons.favorite_rounded, size: 13, color: AppColors.crimson),
                    const SizedBox(width: 2),
                    Text('${donor.donations} donations', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (donor.available ? AppColors.success : AppColors.textMuted).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        donor.available ? '✓ Available' : '✗ Unavailable',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: donor.available ? AppColors.success : AppColors.textMuted),
                      ),
                    ),
                    const Spacer(),
                    Text('Last donated: ${donor.lastDonated}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 2. Need Blood Page ───────────────────────────────────────────────────────

class NeedBloodPage extends StatelessWidget {
  const NeedBloodPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PageHeader(title: 'Need Blood?', subtitle: 'Browse active blood requests', icon: Icons.bloodtype_rounded),
        _buildSOS(context),
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildSOS(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B0000), Color(0xFF300000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.crimson.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EMERGENCY?', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 2)),
              SizedBox(height: 4),
              Text('Post a Blood\nRequest Now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2)),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.crimson,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            child: const Text('SOS POST', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: requests.length,
      itemBuilder: (_, i) => _RequestCard(req: requests[i]),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final BloodRequest req;
  const _RequestCard({required this.req});

  Color get _urgencyColor {
    switch (req.urgency) {
      case 'critical': return AppColors.urgent;
      case 'urgent': return AppColors.warning;
      default: return AppColors.success;
    }
  }

  IconData get _urgencyIcon {
    switch (req.urgency) {
      case 'critical': return Icons.emergency_rounded;
      case 'urgent': return Icons.priority_high_rounded;
      default: return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _urgencyColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _urgencyColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(_urgencyIcon, size: 14, color: _urgencyColor),
                const SizedBox(width: 6),
                Text(req.urgency.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: _urgencyColor, letterSpacing: 1.5)),
                const Spacer(),
                Text(req.postedTime, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(req.patient, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.local_hospital_rounded, size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Expanded(child: Text(req.hospital, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(req.city, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        BloodTypeBadge(type: req.blood, size: 18),
                        const SizedBox(height: 6),
                        Text(req.units, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.crimson),
                          foregroundColor: AppColors.crimson,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.call_rounded, size: 16),
                        label: const Text('Call Now', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.crimson,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.volunteer_activism_rounded, size: 16),
                        label: const Text('Respond', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 3. Blood Bank Page ───────────────────────────────────────────────────────

class BloodBankPage extends StatelessWidget {
  const BloodBankPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const PageHeader(title: 'Blood Banks', subtitle: 'Live stock levels near you', icon: Icons.local_hospital_rounded),
        _buildLegend(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            itemCount: banks.length,
            itemBuilder: (_, i) => _BankCard(bank: banks[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          const Text('Stock levels: ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          _legendDot(AppColors.success, 'Good'),
          const SizedBox(width: 10),
          _legendDot(AppColors.warning, 'Low'),
          const SizedBox(width: 10),
          _legendDot(AppColors.urgent, 'Critical'),
        ],
      ),
    );
  }

  Widget _legendDot(Color c, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _BankCard extends StatefulWidget {
  final BloodBank bank;
  const _BankCard({required this.bank});

  @override
  State<_BankCard> createState() => _BankCardState();
}

class _BankCardState extends State<_BankCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.bank;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: b.open ? AppColors.crimson.withOpacity(0.2) : Colors.transparent),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.crimson.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_hospital_rounded, color: AppColors.crimson, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Expanded(child: Text(b.city, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Text(b.timing, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (b.open ? AppColors.success : AppColors.textMuted).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(b.open ? 'OPEN' : 'CLOSED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: b.open ? AppColors.success : AppColors.textMuted)),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 13, color: AppColors.warning),
                            const SizedBox(width: 2),
                            Text(b.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Mini stock row (4 groups)
                Row(
                  children: b.stock.entries.take(4).map((e) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 6), child: StockChip(group: e.key, units: e.value)))).toList(),
                ),
                if (_expanded) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: b.stock.entries.skip(4).map((e) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 6), child: StockChip(group: e.key, units: e.value)))).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Expanded(child: Text(b.address, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.crimson),
                            foregroundColor: AppColors.crimson,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.call_rounded, size: 15),
                          label: const Text('Call', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.crimson,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.directions_rounded, size: 15),
                          label: const Text('Navigate', style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_expanded ? 'Show Less' : 'Show All Stock & Details', style: const TextStyle(fontSize: 12, color: AppColors.crimson, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 16, color: AppColors.crimson),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}