import 'package:flutter/material.dart';
import 'main.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(
        backgroundColor: AppColors.bgPage,
        body: Center(child: CircularProgressIndicator(color: AppColors.rose)),
      );

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AuthState.role == 'blood_bank'
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
                              AuthState.name ?? 'User',
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

    final res = await ApiService.patch('profile/', {
      'user_id': AuthState.userId,   // ← was missing
      'is_open': val,
    });

    if (!mounted) return;

    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(val ? '✓ Bank is now Open' : '✓ Bank is now Closed'),
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
  final res = await ApiService.patch('/auth/profile/', {
    'user_id': AuthState.userId,   // ← was missing
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
  late String _gender, _bloodGroup, _lastDonated;
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
    _lastDonated = p['last_donated'] ?? 'Never';
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
    const opts = [
      'Never',
      'Less than 3 months ago',
      '3-6 months ago',
      'More than 6 months ago',
    ];
    return DropdownButtonFormField<String>(
      value: _lastDonated,
      decoration: const InputDecoration(
        labelText: 'Last Donated',
        prefixIcon: Icon(Icons.history_rounded, size: 18),
      ),
      items: opts
          .map(
            (o) => DropdownMenuItem(
              value: o,
              child: Text(o, style: const TextStyle(fontSize: 12)),
            ),
          )
          .toList(),
      onChanged: (v) {
        if (v != null) setState(() => _lastDonated = v);
      },
    );
  }

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
      'last_donated': _lastDonated,
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
