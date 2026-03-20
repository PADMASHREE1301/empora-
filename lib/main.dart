import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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

// ── Step 1: Show SplashScreen for 2.8s ──────────────────────────────────────
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
    // ── Step 2: After splash, wait for auth check to finish ─────────────────
    return const RootRouter();
  }
}

// ── Step 2: Wait for AuthProvider to finish checking saved token ─────────────
class RootRouter extends StatelessWidget {
  const RootRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Still checking saved token — show loading spinner
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

    // Not logged in → Login Screen
    if (!auth.isLoggedIn) return const LoginScreen();

    // Admin → Home Screen (same as users, with extra Admin tab)
    if (auth.isAdmin) return const HomeScreen();

    // New user without founder profile → Onboarding
    if (auth.needsOnboarding) return const OnboardingScreen();

    // Free or Member → Home Screen
    return const HomeScreen();
  }
}