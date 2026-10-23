import 'package:flutter/material.dart';
import 'main.dart';

// ─────────────────────────────────────────────────────────────
// FORGOT PASSWORD — same backend flow as the website
// POST /forgot-password/  →  POST /verify-otp/  →  POST /reset-password/
// ─────────────────────────────────────────────────────────────
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _step = 0; // 0: email, 1: otp, 2: new password, 3: done
  bool _loading = false;
  String? _resetToken;

  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.rose,
      behavior: SnackBarBehavior.floating,
    ),
  );

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
    ),
  );

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Enter a valid email address');
      return;
    }
    setState(() => _loading = true);
    final res = await ApiService.post('/forgot-password/', {'email': email});
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      _showSuccess(res['message'] ?? 'OTP sent to your email');
      setState(() => _step = 1);
    } else {
      _showError(res['message'] ?? 'Could not send OTP');
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length != 6) {
      _showError('Enter the 6-digit OTP');
      return;
    }
    setState(() => _loading = true);
    final res = await ApiService.post('/verify-otp/', {
      'email': _emailCtrl.text.trim(),
      'otp': otp,
    });
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      final data = res['data'];
      _resetToken = data is Map ? data['reset_token'] : null;
      setState(() => _step = 2);
    } else {
      _showError(res['message'] ?? 'Invalid or expired OTP');
    }
  }

  Future<void> _resetPassword() async {
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;
    if (pass.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }
    if (pass != confirm) {
      _showError('Passwords do not match');
      return;
    }
    setState(() => _loading = true);
    final res = await ApiService.post('/reset-password/', {
      'email': _emailCtrl.text.trim(),
      'reset_token': _resetToken,
      'new_password': pass,
    });
    if (!mounted) return;
    setState(() => _loading = false);
    if (res['success'] == true) {
      setState(() => _step = 3);
    } else {
      _showError(res['message'] ?? 'Could not reset password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.inkDark),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _header(),
              const SizedBox(height: 28),
              if (_step < 3) _buildStepIndicator(),
              if (_step < 3) const SizedBox(height: 28),
              if (_step == 0) _emailStep(),
              if (_step == 1) _otpStep(),
              if (_step == 2) _passwordStep(),
              if (_step == 3) _successStep(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    const titles = [
      'Forgot password?',
      'Check your email',
      'Set new password',
      'All done!',
    ];
    const subs = [
      "Enter the email linked to your account and we'll send you a reset code.",
      'Enter the 6-digit code we sent to your email.',
      'Choose a new password for your account.',
      'Your password has been reset successfully.',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titles[_step],
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.inkDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subs[_step],
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (i) {
        final active = i <= _step;
        return Expanded(
          child: Container(
            height: 4,
            margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
            decoration: BoxDecoration(
              color: active ? AppColors.rose : AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  Widget _emailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined, size: 20),
          ),
        ),
        const SizedBox(height: 24),
        _actionButton('Send OTP', _sendOtp),
      ],
    );
  }

  Widget _otpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.rosePale,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'OTP sent to ${_emailCtrl.text.trim()}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.roseDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          style: const TextStyle(
            fontSize: 20,
            letterSpacing: 8,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
          decoration: const InputDecoration(labelText: '6-digit OTP', counterText: ''),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _loading ? null : _sendOtp,
          child: const Text(
            'Resend OTP',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.rose,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _actionButton('Verify OTP', _verifyOtp),
      ],
    );
  }

  Widget _passwordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _passCtrl,
          obscureText: _obscure1,
          decoration: InputDecoration(
            labelText: 'New password',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure1 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure1 = !_obscure1),
            ),
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _confirmCtrl,
          obscureText: _obscure2,
          decoration: InputDecoration(
            labelText: 'Confirm new password',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscure2 ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure2 = !_obscure2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _actionButton('Reset Password', _resetPassword),
      ],
    );
  }

  Widget _successStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.successBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: AppColors.success, size: 36),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Back to Sign In'),
          ),
        ),
      ],
    );
  }

  Widget _actionButton(String label, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : onTap,
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(label),
      ),
    );
  }
}
