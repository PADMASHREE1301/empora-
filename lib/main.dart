// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/pending_approval_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const EmporaApp());
}

class EmporaApp extends StatelessWidget {
  const EmporaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final auth = AuthProvider();
            // Kick off the saved-token check immediately when the provider is created.
            // Once done, auth.isInitialized flips to true and RootRouter rebuilds.
            auth.init();
            return auth;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Empora',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const AppEntry(),
      ),
    );
  }
}

// ── Step 1: Show SplashScreen for 2.8 s ──────────────────────────────────────
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  bool _splashDone = false;

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashScreen(
        onComplete: () => setState(() => _splashDone = true),
      );
    }
    // Step 2: splash finished — hand off to router
    return const RootRouter();
  }
}

// ── Step 2: Route to the correct screen based on auth state ──────────────────
class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // auth.init() hasn't finished checking the saved token yet
    if (!auth.isInitialized) {
      return const Scaffold(
        backgroundColor: AppTheme.primaryDark,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    // No valid session → Login
    if (!auth.isLoggedIn) return const LoginScreen();

    // Admin → Home (admin sees the Admin tab inside HomeScreen)
    if (auth.isAdmin) return const HomeScreen();

    // Logged in but not yet approved by admin → waiting screen
    if (!auth.isApproved) return const PendingApprovalScreen();

    // Approved but hasn't filled in the founder profile → Onboarding
    if (auth.needsOnboarding) return const OnboardingScreen();

    // Fully approved user (free or member) → Home
    return const HomeScreen();
  }
}