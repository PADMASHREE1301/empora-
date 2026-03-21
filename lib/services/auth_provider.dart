import 'package:flutter/foundation.dart';
import 'package:empora/models/user_model.dart';
import 'package:empora/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading      = false;
  bool _isInitialized  = false;
  bool _isApproved     = false; // ← stored independently of UserModel
  String? _error;
  bool _isLoggedIn     = false;

  UserModel? get user        => _user;
  bool get isLoading         => _isLoading;
  bool get isInitialized     => _isInitialized;
  String? get error          => _error;
  bool get isLoggedIn        => _isLoggedIn;
  bool get isMember          => _user?.isMember  ?? false;
  bool get isFree            => !isMember && !isAdmin;
  bool get isAdmin           => _user?.isAdmin   ?? false;
  bool get isApproved        => _isApproved;
  bool get needsOnboarding   => _isLoggedIn && !isAdmin && _isApproved && (_user?.founderProfileComplete != true);

  AuthProvider() {
    _checkLoginStatus();
  }

  // ─── Check existing token on startup ─────────────────────────────
  Future<void> _checkLoginStatus() async {
    final hasToken = await ApiService.isLoggedIn();
    if (!hasToken) {
      _isLoggedIn     = false;
      _isInitialized  = true;
      notifyListeners();
      return;
    }

    try {
      final result = await ApiService.getMe();
      if (result['success'] == true || result['data'] != null) {
        _isLoggedIn = true;
        final rawUser = result['user'] ?? result['data'];
        if (rawUser is Map<String, dynamic>) {
          _user       = UserModel.fromJson(rawUser);
          _isApproved = rawUser['isApproved'] as bool? ?? false;
          // Admins are always considered approved
          if (_user?.isAdmin == true) _isApproved = true;
        }
      } else {
        _isLoggedIn = false;
        await ApiService.clearToken();
      }
    } catch (_) {
      _isLoggedIn = false;
      await ApiService.clearToken();
    }

    _isInitialized = true;
    notifyListeners();
  }

  // ─── Login ────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, dynamic> result = await ApiService.login(
        email: email,
        password: password,
      );

      _isLoading  = false;
      _isLoggedIn = true;

      final rawUser = result['data']?['user'] ?? result['user'] ?? result['data'];
      if (rawUser is Map<String, dynamic>) {
        _user       = UserModel.fromJson(rawUser);
        _isApproved = rawUser['isApproved'] as bool? ?? false;
        if (_user?.isAdmin == true) _isApproved = true;
      }

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isLoading = false;
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Register ─────────────────────────────────────────────────────
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? company,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Map<String, dynamic> result = await ApiService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        company: company,
      );

      _isLoading  = false;
      _isLoggedIn = true;

      final rawUser = result['data']?['user'] ?? result['user'] ?? result['data'];
      if (rawUser is Map<String, dynamic>) {
        _user       = UserModel.fromJson(rawUser);
        _isApproved = rawUser['isApproved'] as bool? ?? false;
        if (_user?.isAdmin == true) _isApproved = true;
      }

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isLoading = false;
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Fetch Profile ────────────────────────────────────────────────
  Future<void> fetchProfile() async {
    try {
      final Map<String, dynamic> result = await ApiService.getMe();
      final rawData = result['user'] ?? result['data'] ?? result;
      if (rawData is Map<String, dynamic>) {
        _user       = UserModel.fromJson(rawData);
        _isApproved = rawData['isApproved'] as bool? ?? false;
        if (_user?.isAdmin == true) _isApproved = true;
        notifyListeners();
      }
    } catch (_) {}
  }

  // ─── Upgrade membership ───────────────────────────────────────────
  Future<bool> upgradeMembership(String plan) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.upgradeMembership(plan: plan);
      _isLoading = false;

      final rawUser = result['user'];
      if (rawUser is Map<String, dynamic>) {
        _user = UserModel.fromJson(rawUser);
      }

      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _isLoading = false;
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {
      await ApiService.clearToken();
    }
    _user       = null;
    _isLoggedIn = false;
    _isApproved = false;
    _error      = null;
    notifyListeners();
  }

  // ─── Clear error ──────────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }
}