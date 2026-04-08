// lib/services/auth_provider.dart

import 'package:flutter/material.dart';
import 'package:empora/services/api_service.dart';

// ─── User model ───────────────────────────────────────────────────────────────
class AppUser {
  final String  id;
  final String  name;
  final String  email;
  final String  role;
  final String  membershipStatus;
  final String? membershipPlan;
  final String? membershipEndDate;
  final String? membershipExpiry;
  final bool    isMember;
  final bool    isAdmin;
  final bool    isApproved;
  final bool    isActive;
  final bool    founderProfileComplete;
  final String? profilePicture;
  final String? phone;
  final String? company;
  final Map<String, dynamic>? founderProfile;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.membershipStatus,
    this.membershipPlan,
    this.membershipEndDate,
    this.membershipExpiry,
    required this.isMember,
    required this.isAdmin,
    required this.isApproved,
    required this.isActive,
    required this.founderProfileComplete,
    this.profilePicture,
    this.phone,
    this.company,
    this.founderProfile,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] ?? json['_id'] ?? '';
    return AppUser(
      id:                     rawId.toString(),
      name:                   json['name']                   as String? ?? '',
      email:                  json['email']                  as String? ?? '',
      role:                   json['role']                   as String? ?? 'free',
      membershipStatus:       json['membershipStatus']       as String? ?? 'inactive',
      membershipPlan:         json['membershipPlan']         as String?,
      membershipEndDate:      json['membershipEndDate']      as String?,
      membershipExpiry:       json['membershipExpiry']       as String?,
      isMember:               json['isMember']               as bool?   ?? false,
      isAdmin:                json['isAdmin']                as bool?   ?? false,
      isApproved:             json['isApproved']             as bool?   ?? false,
      isActive:               json['isActive']               as bool?   ?? true,
      founderProfileComplete: json['founderProfileComplete'] as bool?   ?? false,
      profilePicture:         json['profilePicture']         as String?,
      phone:                  json['phone']                  as String?,
      company:                json['company']                as String?,
      founderProfile:         json['founderProfile']         as Map<String, dynamic>?,
    );
  }
}

// ─── AuthProvider ─────────────────────────────────────────────────────────────
class AuthProvider extends ChangeNotifier {
  AppUser? _user;
  bool     _isLoading     = false;
  bool     _isInitialized = false;
  String?  _error;
  String?  _errorCode;

  // ── Public getters ────────────────────────────────────────────────────────
  AppUser? get user          => _user;
  bool     get isLoading     => _isLoading;
  bool     get isInitialized => _isInitialized;
  String?  get error         => _error;
  String?  get errorCode     => _errorCode;

  bool get isLoggedIn  => _user != null;
  bool get isAdmin     => _user?.isAdmin    ?? false;
  bool get isApproved  => _user?.isApproved ?? false;
  bool get isMember    => _user?.isMember   ?? false;

  /// True when the user is logged in + approved but has NOT completed
  /// the founder profile onboarding. Admins never need onboarding.
  bool get needsOnboarding {
    if (_user == null) return false;
    if (isAdmin)       return false;
    if (!isApproved)   return false;
    return !(_user!.founderProfileComplete);
  }

  // ── Internal helpers ──────────────────────────────────────────────────────
  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void _clearError() {
    _error     = null;
    _errorCode = null;
  }

  // ── App startup — restore saved session ──────────────────────────────────
  Future<void> init() async {
    final loggedIn = await ApiService.isLoggedIn();
    if (loggedIn) {
      await fetchProfile();
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
      final data = await ApiService.register(
        name:     name,
        email:    email,
        password: password,
        phone:    phone,
        company:  company,
      );

      if (data['success'] == true) {
        if (data['user'] != null) {
          _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
        }
        _setLoading(false);
        return true;
      }

      _error     = data['message'] as String? ?? 'Registration failed.';
      _errorCode = data['code']    as String?;
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _error     = e.message;
      _errorCode = null;
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Network error. Please check your connection.';
      _setLoading(false);
      return false;
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final data = await ApiService.login(email: email, password: password);

      if (data['success'] == true) {
        if (data['user'] != null) {
          _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
        }
        _setLoading(false);
        return true;
      }

      _error     = data['message'] as String? ?? 'Login failed.';
      _errorCode = data['code']    as String?;
      _setLoading(false);
      return false;
    } on ApiException catch (e) {
      _error = e.message;
      if (e.statusCode == 403) {
        if (e.message.contains('pending') || e.message.contains('approval')) {
          _errorCode = 'PENDING_APPROVAL';
        } else if (e.message.contains('deactivated')) {
          _errorCode = 'ACCOUNT_DEACTIVATED';
        }
      }
      _setLoading(false);
      return false;
    } catch (_) {
      _error = 'Network error. Please check your connection.';
      _setLoading(false);
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {
      await ApiService.clearToken();
    }
    _user      = null;
    _error     = null;
    _errorCode = null;
    notifyListeners();
  }

  // ── Fetch current profile from /api/auth/me ───────────────────────────────
  // Call this: on app init, after payment, and on app resume.
  Future<void> fetchProfile() async {
    final loggedIn = await ApiService.isLoggedIn();
    if (!loggedIn) return;

    try {
      final data = await ApiService.getMe();
      if (data['user'] != null) {
        _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
        notifyListeners();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        _user = null;
        await ApiService.clearToken();
        notifyListeners();
      }
    } catch (_) {
      // Network error — keep existing state
    }
  }

  // ── Update user directly from payment verify response ─────────────────────
  // FIX: After payment succeeds, the verify response already contains the
  // updated user object. Apply it immediately so the UI reflects membership
  // without waiting for a /me round-trip to complete.
  void updateUserFromPaymentResponse(Map<String, dynamic> userJson) {
    _user = AppUser.fromJson(userJson);
    notifyListeners();
  }

  // ── Update local user (e.g. after any profile change) ────────────────────
  void updateUser(AppUser updated) {
    _user = updated;
    notifyListeners();
  }

  // ── Mark founder profile as complete locally ──────────────────────────────
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
      membershipExpiry:       _user!.membershipExpiry,
      isMember:               _user!.isMember,
      isAdmin:                _user!.isAdmin,
      isApproved:             _user!.isApproved,
      isActive:               _user!.isActive,
      founderProfileComplete: true,
      profilePicture:         _user!.profilePicture,
      phone:                  _user!.phone,
      company:                _user!.company,
      founderProfile:         _user!.founderProfile,
    );
    notifyListeners();
  }
}