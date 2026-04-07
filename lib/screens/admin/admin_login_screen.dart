// lib/screens/admin/admin_login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:empora/theme/app_theme.dart';
import 'package:empora/services/api_service.dart';
import 'package:empora/screens/admin/admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey       = GlobalKey<FormState>();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _localAuth     = LocalAuthentication();

  bool _obscure        = true;
  bool _isLoading      = false;
  bool _biometricAvail = false;
  bool _biometricSaved = false;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Keys for SharedPreferences ────────────────────────────────────────────
  static const _kEmail    = 'admin_email';
  static const _kPassword = 'admin_password';
  static const _kBioSaved = 'admin_bio_saved';

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));

    _animCtrl.forward();
    _initBiometrics();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Check biometric availability & saved credentials ─────────────────────
  Future<void> _initBiometrics() async {
    try {
      final canCheck  = await _localAuth.canCheckBiometrics;
      final isSupport = await _localAuth.isDeviceSupported();
      final prefs     = await SharedPreferences.getInstance();
      final bioSaved  = prefs.getBool(_kBioSaved) ?? false;

      setState(() {
        _biometricAvail = canCheck && isSupport;
        _biometricSaved = bioSaved;
      });

      // Auto-trigger biometric if credentials were saved previously
      if (_biometricAvail && _biometricSaved) {
        await Future.delayed(const Duration(milliseconds: 600));
        _loginWithBiometric();
      }
    } catch (_) {}
  }

  // ── Biometric login ───────────────────────────────────────────────────────
  Future<void> _loginWithBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Verify your identity to access Admin Panel',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );

      if (!authenticated) return;

      final prefs    = await SharedPreferences.getInstance();
      final email    = prefs.getString(_kEmail);
      final password = prefs.getString(_kPassword);

      if (email == null || password == null) {
        _showError('No saved credentials. Please log in with email first.');
        return;
      }

      _emailCtrl.text    = email;
      _passwordCtrl.text = password;
      await _login(saveBiometric: false);
    } on PlatformException catch (e) {
      _showError('Biometric error: ${e.message}');
    }
  }

  // ── Email/password login ──────────────────────────────────────────────────
  Future<void> _login({bool saveBiometric = true}) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      final res = await ApiService.adminPost('/auth/admin-login', {
        'email':    _emailCtrl.text.trim(),
        'password': _passwordCtrl.text,
      });

      if (res['success'] == true) {
        // Save token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_token', res['token'] as String);

        // Ask to save biometrics (only after manual login)
        if (saveBiometric && _biometricAvail && !_biometricSaved) {
          await _askSaveBiometric(
            email:    _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
        }

        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            (_) => false,
          );
        }
      } else {
        _showError(res['message'] as String? ?? 'Login failed.');
      }
    } catch (e) {
      _showError('Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Ask user to enable biometric ──────────────────────────────────────────
  Future<void> _askSaveBiometric({
    required String email,
    required String password,
  }) async {
    final save = await showDialog<bool>(
      context: context,
      builder: (_) => Theme(
        data: AppTheme.adminTheme,
        child: AlertDialog(
          backgroundColor: AppTheme.adminCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppTheme.adminBorder),
          ),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.adminAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fingerprint,
                  color: AppTheme.adminAccent, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Enable Biometric',
                style: GoogleFonts.montserrat(
                    color: AppTheme.adminTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ]),
          content: Text(
            'Use fingerprint or face ID to log in faster next time.',
            style: GoogleFonts.inter(
                color: AppTheme.adminTextSecond, fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Not now',
                  style: GoogleFonts.inter(color: AppTheme.adminTextSecond)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.adminAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Enable',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );

    if (save == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kEmail, email);
      await prefs.setString(_kPassword, password);
      await prefs.setBool(_kBioSaved, true);
    }
  }

  void _showError(String msg) {
    if (mounted) setState(() => _error = msg);
  }

  // ── UI ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.adminTheme,
      child: Scaffold(
        backgroundColor: AppTheme.adminBg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const SizedBox(height: 52),

                        // ── Logo ──────────────────────────────────────────
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.adminAccent.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'E',
                              style: GoogleFonts.montserrat(
                                color: AppTheme.adminBg,
                                fontWeight: FontWeight.w900,
                                fontSize: 36,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        Text(
                          'Admin Panel',
                          style: GoogleFonts.montserrat(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.adminTextPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'EMPORA • Restricted Access',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.adminTextSecond,
                            letterSpacing: 1.5,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // ── Form card ─────────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.adminCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.adminBorder),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                // ── Error banner ──────────────────────────
                                if (_error != null) ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppTheme.adminError.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: AppTheme.adminError.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(children: [
                                      const Icon(Icons.error_outline,
                                          color: AppTheme.adminError, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(_error!,
                                            style: GoogleFonts.inter(
                                                color: AppTheme.adminError,
                                                fontSize: 12)),
                                      ),
                                    ]),
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // ── Email ─────────────────────────────────
                                Text('Admin Email',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.adminTextSecond,
                                        letterSpacing: 0.5)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  style: GoogleFonts.inter(
                                      color: AppTheme.adminTextPrimary),
                                  decoration: InputDecoration(
                                    hintText: 'admin@empora.com',
                                    prefixIcon: Icon(Icons.email_outlined,
                                        color: AppTheme.adminTextSecond, size: 18),
                                    filled: true,
                                    fillColor: AppTheme.adminCardAlt,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppTheme.adminBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppTheme.adminBorder),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppTheme.adminAccent, width: 2),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Enter email';
                                    if (!v.contains('@')) return 'Invalid email';
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // ── Password ──────────────────────────────
                                Text('Password',
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.adminTextSecond,
                                        letterSpacing: 0.5)),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscure,
                                  style: GoogleFonts.inter(
                                      color: AppTheme.adminTextPrimary),
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    prefixIcon: Icon(Icons.lock_outline,
                                        color: AppTheme.adminTextSecond, size: 18),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: AppTheme.adminTextSecond,
                                        size: 18,
                                      ),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                    filled: true,
                                    fillColor: AppTheme.adminCardAlt,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppTheme.adminBorder),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppTheme.adminBorder),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                          color: AppTheme.adminAccent, width: 2),
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Enter password';
                                    if (v.length < 6) return 'Min 6 characters';
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),

                                // ── Login button ──────────────────────────
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : () => _login(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.adminAccent,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2),
                                          )
                                        : Text(
                                            'Sign In',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Biometric button ──────────────────────────────
                        Row(children: [
                          const Expanded(child: Divider(color: AppTheme.adminBorder)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or',
                                style: GoogleFonts.inter(
                                    color: AppTheme.adminTextSecond,
                                    fontSize: 12)),
                          ),
                          const Expanded(child: Divider(color: AppTheme.adminBorder)),
                        ]),

                        const SizedBox(height: 20),

                        GestureDetector(
                          onTap: _biometricAvail ? _loginWithBiometric : null,
                          child: AnimatedOpacity(
                            opacity: _biometricAvail ? 1.0 : 0.45,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.adminCard,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: _biometricAvail
                                        ? AppTheme.adminAccent.withValues(alpha: 0.4)
                                        : AppTheme.adminBorder),
                              ),
                              child: Column(children: [
                                Icon(
                                  Icons.fingerprint,
                                  size: 36,
                                  color: _biometricAvail
                                      ? AppTheme.adminAccent
                                      : AppTheme.adminTextSecond,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _biometricAvail
                                      ? (_biometricSaved
                                          ? 'Login with Biometric'
                                          : 'Set Up Biometric Login')
                                      : 'Biometric Not Available',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _biometricAvail
                                        ? AppTheme.adminAccent
                                        : AppTheme.adminTextSecond,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _biometricAvail
                                      ? 'Fingerprint or Face ID'
                                      : 'Not supported on this device',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppTheme.adminTextSecond,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ),

                        const Expanded(child: SizedBox()),

                        // ── Footer ────────────────────────────────────────
                        Text(
                          'Empora Admin • Restricted Access Only',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppTheme.adminTextSecond,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}