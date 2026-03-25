// lib/services/auth_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─── User model ───────────────────────────────────────────────────────────────
class AppUser {
  final String  id;
  final String  name;
  final String  email;
  final String  role;
  final String  membershipStatus;
  final String? membershipPlan;
  final String? membershipEndDate;
  final bool    isMember;
  final bool    isAdmin;
  final bool    isApproved;
  final bool    isActive;
  final bool    founderProfileComplete;
  final String? profilePicture;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.membershipStatus,
    this.membershipPlan,
    this.membershipEndDate,
    required this.isMember,
    required this.isAdmin,
    required this.isApproved,
    required this.isActive,
    required this.founderProfileComplete,
    this.profilePicture,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id:                     (json['id'] ?? json['_id'] ?? '').toString(),
      name:                   json['name']                   as String? ?? '',
      email:                  json['email']                  as String? ?? '',
      role:                   json['role']                   as String? ?? 'free',
      membershipStatus:       json['membershipStatus']       as String? ?? 'inactive',
      membershipPlan:         json['membershipPlan']         as String?,
      membershipEndDate:      json['membershipEndDate']      as String?,
      isMember:               json['isMember']               as bool?   ?? false,
      isAdmin:                json['isAdmin']                as bool?   ?? false,
      isApproved:             json['isApproved']             as bool?   ?? false,
      isActive:               json['isActive']               as bool?   ?? true,
      founderProfileComplete: json['founderProfileComplete'] as bool?   ?? false,
      profilePicture:         json['profilePicture']         as String?,
    );
  }
}

// ─── AuthProvider ─────────────────────────────────────────────────────────────
class AuthProvider extends ChangeNotifier {
  // Change this to your actual backend URL.
  // For Android emulator use 10.0.2.2, for iOS simulator use 127.0.0.1
  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000/api',
  );
  static const String _tokenKey = 'auth_token';

  AppUser? _user;
  String?  _token;
  bool     _isLoading     = false;
  bool     _isInitialized = false; // ← true once the startup token-check is done
  String?  _error;
  String?  _errorCode;             // ← 'PENDING_APPROVAL' | 'ACCOUNT_DEACTIVATED'

  // ── Public getters ────────────────────────────────────────────────────────

  AppUser? get user          => _user;
  String?  get token         => _token;
  bool     get isLoading     => _isLoading;
  bool     get isInitialized => _isInitialized; // used by RootRouter in main.dart
  String?  get error         => _error;
  String?  get errorCode     => _errorCode;     // used by login_screen.dart

  bool get isLoggedIn  => _user != null && _token != null;
  bool get isAdmin     => _user?.isAdmin    ?? false;
  bool get isApproved  => _user?.isApproved ?? false;
  bool get isMember    => _user?.isMember   ?? false;

  /// True when the user is logged in, approved, but has NOT yet completed
  /// the founder profile onboarding flow.
  /// Admins never need onboarding.
  bool get needsOnboarding {
    if (_user == null)   return false;
    if (isAdmin)         return false;
    if (!isApproved)     return false;
    return !(_user!.founderProfileComplete);
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _setError(String? msg, {String? code}) {
    _error     = msg;
    _errorCode = code;
    notifyListeners();
  }

  void _clearError() {
    _error     = null;
    _errorCode = null;
  }

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // ── Token persistence ─────────────────────────────────────────────────────

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<String?> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ── App startup: restore saved session ───────────────────────────────────
  //
  // Call this once from EmporaApp (via ChangeNotifierProvider create callback
  // or from initState of AppEntry). It checks for a saved token, fetches the
  // profile if one exists, then sets isInitialized = true so RootRouter knows
  // it's safe to decide which screen to show.

  Future<void> init() async {
    final saved = await _loadToken();
    if (saved != null) {
      _token = saved;
      await fetchProfile(); // populates _user
    }
    _isInitialized = true;
    notifyListeners();
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? company,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final body = {
        'name':     name,
        'email':    email,
        'password': password,
        if (phone   != null && phone.isNotEmpty)   'phone':   phone,
        if (company != null && company.isNotEmpty) 'company': company,
      };

      final res = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 201 && data['success'] == true) {
        _token = data['token'] as String?;
        if (_token != null) await _saveToken(_token!);
        if (data['user'] != null) {
          _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
        }
        _setLoading(false);
        return true;
      } else {
        _setError(data['message'] as String? ?? 'Registration failed.');
        _setLoading(false);
        return false;
      }
    } catch (_) {
      _setError('Network error. Please check your connection.');
      _setLoading(false);
      return false;
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(res.body) as Map<String, dynamic>;

      if (res.statusCode == 200 && data['success'] == true) {
        _token = data['token'] as String?;
        if (_token != null) await _saveToken(_token!);
        if (data['user'] != null) {
          _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
        }
        _setLoading(false);
        return true;
      } else {
        // Capture backend error code for login_screen.dart to handle
        _setError(
          data['message'] as String? ?? 'Login failed.',
          code: data['code'] as String?,
        );
        _setLoading(false);
        return false;
      }
    } catch (_) {
      _setError('Network error. Please check your connection.');
      _setLoading(false);
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: _authHeaders,
      );
    } catch (_) {
      // Ignore — clear local state regardless
    }
    _user  = null;
    _token = null;
    _clearError();
    await _clearToken();
    notifyListeners();
  }

  // ── Fetch current profile from /api/auth/me ───────────────────────────────

  Future<void> fetchProfile() async {
    if (_token == null) return;
    try {
      final res = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: _authHeaders,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['user'] != null) {
          _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
          notifyListeners();
        }
      } else if (res.statusCode == 401) {
        // Token expired or invalid — clear session silently
        _user  = null;
        _token = null;
        await _clearToken();
        notifyListeners();
      }
    } catch (_) {
      // Network error on startup — keep existing state, don't crash
    }
  }

  // ── Update local user (e.g. after membership upgrade) ────────────────────

  void updateUser(AppUser updated) {
    _user = updated;
    notifyListeners();
  }

  // ── Mark founder profile as complete locally ──────────────────────────────
  //    Call this after OnboardingScreen saves successfully so needsOnboarding
  //    flips to false immediately without a round-trip to the server.

  void markOnboardingComplete() {
    if (_user == null) return;
    _user = AppUser(
      id:                     _user!.id,
      name:                   _user!.name,
      email:                  _user!.email,
      role:                   _user!.role,
      membershipStatus:       _user!.membershipStatus,
      membershipPlan:         _user!.membershipPlan,
      membershipEndDate:      _user!.membershipEndDate,
      isMember:               _user!.isMember,
      isAdmin:                _user!.isAdmin,
      isApproved:             _user!.isApproved,
      isActive:               _user!.isActive,
      founderProfileComplete: true,   // ← flip the flag
      profilePicture:         _user!.profilePicture,
    );
    notifyListeners();
  }
}