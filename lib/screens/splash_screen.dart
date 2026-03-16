import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:empora/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );

    _scaleAnim = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)),
    );

    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 0.8, curve: Curves.easeOut)),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryDark, AppTheme.primary, AppTheme.primaryLight],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Background geometric decoration
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              right: 40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),

            // Main content
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Transform.scale(
                        scale: _scaleAnim.value,
                        child: FadeTransition(
                          opacity: _fadeAnim,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryDark.withOpacity(0.4),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'E',
                                style: GoogleFonts.montserrat(
                                  fontSize: 60,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // App Name
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnim.value),
                          child: Text(
                            'EMPORA',
                            style: GoogleFonts.montserrat(
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Tagline
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: Transform.translate(
                          offset: Offset(0, _slideAnim.value),
                          child: Text(
                            'Empowering Business Solutions',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 80),

                      // Loading indicator
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.7),
                            ),
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Bottom version
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _fadeAnim,
                builder: (context, child) => FadeTransition(
                  opacity: _fadeAnim,
                  child: Text(
                    'Version 1.0.0',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}