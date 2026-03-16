import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:empora/theme/app_theme.dart';
import 'package:empora/services/auth_provider.dart';
import 'package:empora/screens/home_screen.dart';
import 'package:empora/screens/payment_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }


  void _showUpgradePopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UpgradePopup(
        onContinueFree: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        },
        onUpgrade: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          ).then((_) {
            // Navigate to PaymentScreen after HomeScreen loads
          });
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PaymentScreen()),
          );
        },
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final success = await auth.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      company: _companyController.text.trim(),
    );
    if (success && mounted) {
      _showUpgradePopup();
    }
    if (!success && mounted && auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error!),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primaryDark, AppTheme.primary],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Back + Title
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Create Account',
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 44),
                    child: Text(
                      'Join Empora today',
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Form card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Personal Info'),
                          const SizedBox(height: 16),

                          _buildLabel('Full Name'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              
                              prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Enter your name' : null,
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Email Address'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              
                              prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textSecondary),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter your email';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Phone Number'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              
                              prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Company Name'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _companyController,
                            decoration: const InputDecoration(
                              
                              prefixIcon: Icon(Icons.business_outlined, color: AppTheme.textSecondary),
                            ),
                          ),

                          const SizedBox(height: 24),
                          _buildSectionHeader('Security'),
                          const SizedBox(height: 16),

                          _buildLabel('Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                             
                              prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter a password';
                              if (v.length < 6) return 'Minimum 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildLabel('Confirm Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: InputDecoration(
                              hintText: 'Re-enter password',
                              prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Confirm your password';
                              if (v != _passwordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),

                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: auth.isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : Text(
                                      'Create Account',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: GoogleFonts.inter(color: AppTheme.textSecondary),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }
}
// ─── Upgrade Popup shown after registration ────────────────────────────────────
class _UpgradePopup extends StatefulWidget {
  final VoidCallback onContinueFree;
  final VoidCallback onUpgrade;
  const _UpgradePopup({required this.onContinueFree, required this.onUpgrade});
  @override
  State<_UpgradePopup> createState() => _UpgradePopupState();
}

class _UpgradePopupState extends State<_UpgradePopup> {
  String _selected = 'monthly';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [

            // ── Header gradient ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1A3A6B), Color(0xFF2756A8)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(children: [
                const Icon(Icons.workspace_premium, color: Color(0xFFF5A623), size: 44),
                const SizedBox(height: 10),
                Text('Welcome to EMPORA! 🎉',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('Choose how you want to get started',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.8), fontSize: 13)),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [

                // ── Plan cards ──────────────────────────────────────────
                Row(children: [
                  // FREE
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = 'free'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _selected == 'free'
                              ? const Color(0xFF1A3A6B).withOpacity(0.06)
                              : Colors.white,
                          border: Border.all(
                            color: _selected == 'free'
                                ? const Color(0xFF1A3A6B)
                                : const Color(0xFFE8EDF2),
                            width: _selected == 'free' ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Icon(Icons.person_outline,
                                color: Color(0xFF1A3A6B), size: 20),
                            if (_selected == 'free')
                              const Icon(Icons.check_circle,
                                  color: Color(0xFF1A3A6B), size: 16),
                          ]),
                          const SizedBox(height: 8),
                          Text('Free',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: const Color(0xFF1A1A2E))),
                          const SizedBox(height: 2),
                          Text('₹0 forever',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A3A6B))),
                          const SizedBox(height: 6),
                          _miniFeature('2 modules'),
                          _miniFeature('Basic access'),
                          _miniFeature('No AI chat'),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // MONTHLY
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = 'monthly'),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _selected == 'monthly'
                              ? const Color(0xFFF5A623).withOpacity(0.06)
                              : Colors.white,
                          border: Border.all(
                            color: _selected == 'monthly'
                                ? const Color(0xFFF5A623)
                                : const Color(0xFFE8EDF2),
                            width: _selected == 'monthly' ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            const Icon(Icons.workspace_premium,
                                color: Color(0xFFF5A623), size: 20),
                            if (_selected == 'monthly')
                              const Icon(Icons.check_circle,
                                  color: Color(0xFFF5A623), size: 16),
                          ]),
                          const SizedBox(height: 8),
                          Text('Monthly',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: const Color(0xFF1A1A2E))),
                          const SizedBox(height: 2),
                          Text('₹999/mo',
                              style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFF5A623))),
                          const SizedBox(height: 6),
                          _miniFeature('All 10 modules'),
                          _miniFeature('AI chat advisor'),
                          _miniFeature('PDF reports'),
                        ]),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                // YEARLY
                GestureDetector(
                  onTap: () => setState(() => _selected = 'yearly'),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _selected == 'yearly'
                          ? const Color(0xFF27AE60).withOpacity(0.06)
                          : Colors.white,
                      border: Border.all(
                        color: _selected == 'yearly'
                            ? const Color(0xFF27AE60)
                            : const Color(0xFFE8EDF2),
                        width: _selected == 'yearly' ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(children: [
                      const Icon(Icons.workspace_premium,
                          color: Color(0xFF27AE60), size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text('Yearly',
                              style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: const Color(0xFF1A1A2E))),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF27AE60),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('Save 33%',
                                style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ]),
                        Text('₹7,999/year  •  All features',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: const Color(0xFF6B7C93))),
                      ])),
                      if (_selected == 'yearly')
                        const Icon(Icons.check_circle,
                            color: Color(0xFF27AE60), size: 18),
                    ]),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Action buttons ────────────────────────────────────────
                if (_selected == 'free')
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: widget.onContinueFree,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF1A3A6B)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Continue with Free Plan',
                          style: GoogleFonts.inter(
                              color: const Color(0xFF1A3A6B),
                              fontWeight: FontWeight.w700)),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: widget.onUpgrade,
                      icon: const Icon(Icons.lock_open, size: 18),
                      label: Text(
                        _selected == 'yearly'
                            ? 'Pay ₹7,999 & Unlock All'
                            : 'Pay ₹999 & Unlock All',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: _selected == 'yearly'
                            ? const Color(0xFF27AE60)
                            : const Color(0xFFF5A623),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                    ),
                  ),

                const SizedBox(height: 10),
                TextButton(
                  onPressed: widget.onContinueFree,
                  child: Text('Maybe later',
                      style: GoogleFonts.inter(
                          color: const Color(0xFF6B7C93), fontSize: 13)),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _miniFeature(String text) => Padding(
    padding: const EdgeInsets.only(top: 3),
    child: Row(children: [
      const Icon(Icons.check, size: 11, color: Color(0xFF27AE60)),
      const SizedBox(width: 4),
      Text(text,
          style: GoogleFonts.inter(
              fontSize: 10, color: const Color(0xFF6B7C93))),
    ]),
  );
}