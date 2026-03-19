import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'main.dart';
import 'donor_tab.dart';

// ─────────────────────────────────────────────────────────────
// BLOOD BANK MODEL
// ─────────────────────────────────────────────────────────────
class BloodBankModel {
  final int id;
  final String name, city, address, phone, timing, email;
  final Map<String, int> stock;
  final double rating;
  final bool isOpen;
  final double? lat, lng;

  const BloodBankModel({
    required this.id,
    required this.name,
    required this.city,
    required this.address,
    required this.phone,
    required this.timing,
    required this.email,
    required this.stock,
    required this.rating,
    required this.isOpen,
    this.lat,
    this.lng,
  });

  factory BloodBankModel.fromJson(Map<String, dynamic> j) {
    final raw = j['stock'] as Map<String, dynamic>? ?? {};
    final stock = raw.map((k, v) => MapEntry(k, (v as num).toInt()));
    return BloodBankModel(
      id: j['id'],
      name: j['bank_name'] ?? '',
      city: j['city'] ?? '',
      address: j['bank_address'] ?? '',
      phone: j['bank_phone'] ?? '',
      timing: j['timing'] ?? '',
      email: j['email'] ?? '',
      stock: stock,
      rating: (j['rating'] as num?)?.toDouble() ?? 0.0,
      isOpen: j['is_open'] ?? false,
      lat: (j['latitude'] as num?)?.toDouble(),
      lng: (j['longitude'] as num?)?.toDouble(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BLOOD BANK TAB
// ─────────────────────────────────────────────────────────────
class BloodBankTab extends StatefulWidget {
  const BloodBankTab({super.key});
  @override
  State<BloodBankTab> createState() => _BloodBankTabState();
}

class _BloodBankTabState extends State<BloodBankTab> {
  List<BloodBankModel> _banks = [];
  List<BloodBankModel> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/blood-banks/');
      if (res['success'] == true) {
        final list = (res['data'] as List)
            .map((e) => BloodBankModel.fromJson(e))
            .toList();
        setState(() {
          _banks = list;
          _filter();
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _banks
          .where(
            (b) =>
                q.isEmpty ||
                b.name.toLowerCase().contains(q) ||
                b.city.toLowerCase().contains(q),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: InfoRedzAppBar(
        title: 'Blood Banks',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.rose),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DonorMapScreen()),
        ),
        backgroundColor: AppColors.rose,
        icon: const Icon(Icons.map_rounded, color: Colors.white),
        label: const Text(
          'View on Map',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildLegend(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.rose),
                  )
                : RefreshIndicator(
                    color: AppColors.rose,
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? _buildEmpty()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) =>
                                _BankCard(bank: _filtered[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14, color: AppColors.textBody),
        decoration: InputDecoration(
          hintText: 'Search blood banks by name or city...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
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

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          const Text(
            'Stock: ',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
          _dot(AppColors.success, 'Good (15+)'),
          const SizedBox(width: 10),
          _dot(AppColors.warning, 'Low (5-14)'),
          const SizedBox(width: 10),
          _dot(AppColors.danger, 'Critical (<5)'),
        ],
      ),
    );
  }

  Widget _dot(Color c, String l) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(l, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
    ],
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.local_hospital_rounded,
          size: 56,
          color: AppColors.rose.withOpacity(0.25),
        ),
        const SizedBox(height: 12),
        const Text(
          'No blood banks found',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// BLOOD BANK CARD
// ─────────────────────────────────────────────────────────────
class _BankCard extends StatelessWidget {
  final BloodBankModel bank;
  const _BankCard({required this.bank});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: bank.isOpen ? AppColors.rose.withOpacity(0.25) : null,
      padding: EdgeInsets.zero,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => BloodBankDetailScreen(bank: bank)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildStockRow(),
                const SizedBox(height: 10),
                _buildFooter(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.rosePale,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.rose.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              color: AppColors.rose,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bank.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.inkDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 11,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      bank.city,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.inkLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.access_time_rounded,
                      size: 11,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      bank.timing,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.inkLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _openBadge(),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 12,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    bank.rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _openBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: bank.isOpen ? AppColors.successBg : const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      bank.isOpen ? 'OPEN' : 'CLOSED',
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w900,
        color: bank.isOpen ? AppColors.success : AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    ),
  );

  Widget _buildStockRow() {
    final entries = bank.stock.entries.take(4).toList();
    return Row(
      children: entries
          .map(
            (e) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _StockChip(group: e.key, units: e.value),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.chevron_right_rounded,
          size: 14,
          color: AppColors.rose,
        ),
        const SizedBox(width: 2),
        const Text(
          'View all stock & details',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.rose,
          ),
        ),
        const Spacer(),
        _miniBtn(Icons.call_rounded, 'Call', () {}),
        const SizedBox(width: 8),
        _miniBtn(Icons.directions_rounded, 'Navigate', () {}),
      ],
    );
  }

  Widget _miniBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.rose,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// STOCK CHIP
// ─────────────────────────────────────────────────────────────
class _StockChip extends StatelessWidget {
  final String group;
  final int units;
  const _StockChip({required this.group, required this.units});

  Color get _color {
    if (units == 0) return AppColors.textMuted;
    if (units < 5) return AppColors.danger;
    if (units < 15) return AppColors.warning;
    return AppColors.success;
  }

  Color get _bg {
    if (units == 0) return const Color(0xFFF5F5F5);
    if (units < 5) return const Color(0xFFFEF2F2);
    if (units < 15) return AppColors.warningBg;
    return AppColors.successBg;
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      color: _bg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _color.withOpacity(0.3)),
    ),
    child: Column(
      children: [
        Text(
          group,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textBody,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$units',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: _color,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// BLOOD BANK DETAIL SCREEN
// ─────────────────────────────────────────────────────────────
class BloodBankDetailScreen extends StatelessWidget {
  final BloodBankModel bank;
  const BloodBankDetailScreen({super.key, required this.bank});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(context),
          SliverToBoxAdapter(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 160,
      pinned: true,
      backgroundColor: AppColors.rose,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.rose, AppColors.roseDark],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  bank.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 13,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      bank.city,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildStockCard(),
          const SizedBox(height: 16),
          _buildActionButtons(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return AppCard(
      child: Column(
        children: [
          _infoRow(Icons.access_time_rounded, 'Timing', bank.timing),
          _divider(),
          _infoRow(Icons.location_on_outlined, 'Address', bank.address),
          _divider(),
          _infoRow(Icons.phone_outlined, 'Phone', bank.phone),
          _divider(),
          _infoRow(
            Icons.star_rounded,
            'Rating',
            '${bank.rating.toStringAsFixed(1)} / 5.0',
          ),
          _divider(),
          _infoRow(
            Icons.circle_rounded,
            'Status',
            bank.isOpen ? 'Currently Open' : 'Currently Closed',
            valueColor: bank.isOpen ? AppColors.success : AppColors.danger,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(icon, size: 16, color: AppColors.rose),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textBody,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    ),
  );

  Widget _divider() => const Divider(color: AppColors.divider, height: 1);

  Widget _buildStockCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.water_drop_rounded, size: 16, color: AppColors.rose),
              SizedBox(width: 8),
              Text(
                'Blood Stock Availability',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.inkDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: bank.stock.entries
                .map((e) => _StockChip(group: e.key, units: e.value))
                .toList(),
          ),
          const SizedBox(height: 10),
          const Text(
            '* Units shown are approximate. Call to confirm.',
            style: TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.rose,
              side: const BorderSide(color: AppColors.rose),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.call_rounded, size: 18),
            label: const Text(
              'Call Bank',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rose,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.directions_rounded, size: 18),
            label: const Text(
              'Navigate',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}
