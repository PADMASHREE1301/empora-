import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:empora/theme/app_theme.dart';
import 'package:empora/services/auth_provider.dart';
import 'package:empora/screens/register_screen.dart';
import 'package:empora/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey      = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isAdminMode   = false; // activated by tapping E logo 3 times
  int  _logoTapCount  = 0;

  late AnimationController _animController;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Tap E logo to enter admin mode ───────────────────────────────────────
  void _onLogoTap() {
    if (_isAdminMode) {
      // Already in admin mode — tap again to exit
      _exitAdminMode();
      return;
    }
    _logoTapCount++;
    if (_logoTapCount >= 3) {
      _logoTapCount = 0;
      setState(() {
        _isAdminMode = true;
        _emailCtrl.clear();
        _passwordCtrl.clear();
      });
    }
  }

  void _exitAdminMode() {
    setState(() {
      _isAdminMode  = false;
      _logoTapCount = 0;
      _emailCtrl.clear();
      _passwordCtrl.clear();
    });
  }

  // ── Route after login ─────────────────────────────────────────────────────
  // RootRouter in main.dart handles the actual routing based on auth state.
  // We just pop back to root and let RootRouter decide.
  void _navigateAfterLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth    = context.read<AuthProvider>();
    final success = await auth.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
    if (success && mounted) {
      if (_isAdminMode && !auth.isAdmin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Access denied. Not an admin account.'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        await auth.logout();
        return;
      }
      _navigateAfterLogin();
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

  void _skip() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // Top gradient — turns dark in admin mode
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isAdminMode
                    ? const [Color(0xFF0D1B2A), Color(0xFF1B263B)]
                    : const [AppTheme.primaryDark, AppTheme.primary],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),

          // Decorative circle
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // ── Top row ──────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // E logo — tap 3x to enter admin mode, tap again to exit
                          GestureDetector(
                            onTap: _onLogoTap,
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: _isAdminMode
                                        ? Border.all(color: Colors.amberAccent, width: 2)
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'E',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: _isAdminMode
                                            ? const Color(0xFF0D1B2A)
                                            : AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'EMPORA',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Back button (admin mode only)
                          if (_isAdminMode) GestureDetector(
                            onTap: _exitAdminMode,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_isAdminMode) ...[
                                    const Icon(Icons.arrow_back_ios, color: Colors.white, size: 12),
                                    const SizedBox(width: 4),
                                    Text('Back',
                                        style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14)),
                                  ] else ...[
                                    // Skip removed - login required
                                    const SizedBox.shrink(),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // Title
                      Text(
                        _isAdminMode ? 'Admin\nPortal 🔐' : 'Welcome\nBack 👋',
                        style: GoogleFonts.montserrat(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isAdminMode
                            ? 'Sign in with your admin credentials'
                            : 'Sign in to your Empora account',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 44),

                      // ── Form card ─────────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.12),
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
                              // Admin badge
                              if (_isAdminMode) ...[
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0D1B2A).withOpacity(0.07),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFF0D1B2A).withOpacity(0.2)),
                                  ),
                                  child: Row(children: [
                                    const Icon(Icons.admin_panel_settings,
                                        color: Color(0xFF0D1B2A), size: 18),
                                    const SizedBox(width: 8),
                                    Text('Admin Access',
                                        style: GoogleFonts.inter(
                                          color: const Color(0xFF0D1B2A),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        )),
                                  ]),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Email
                              _Label('Email Address'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: 'you@company.com',
                                  prefixIcon: Icon(Icons.email_outlined,
                                      color: AppTheme.textSecondary),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Enter your email';
                                  if (!v.contains('@')) return 'Enter a valid email';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              // Password
                              _Label('Password'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordCtrl,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(Icons.lock_outline,
                                      color: AppTheme.textSecondary),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppTheme.textSecondary,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Enter your password';
                                  if (v.length < 6) return 'Minimum 6 characters';
                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.primaryLight,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Sign In button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: auth.isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isAdminMode
                                        ? const Color(0xFF0D1B2A)
                                        : AppTheme.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2),
                                        )
                                      : Text(
                                          _isAdminMode ? 'Sign In as Admin' : 'Sign In',
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

                      const SizedBox(height: 28),

                      // Register link — hidden in admin mode
                      if (!_isAdminMode)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: GoogleFonts.inter(color: AppTheme.textSecondary),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const RegisterScreen()),
                              ),
                              child: Text(
                                'Register',
                                style: GoogleFonts.inter(
                                  color: AppTheme.primaryLight,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                      // Skip button — only shown in normal mode
                      if (!_isAdminMode) ...[
                        const SizedBox(height: 12),
                        Center(
                          child: GestureDetector(
                            onTap: _skip,
                            child: Text(
                              'Skip for now',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
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