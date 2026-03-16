// lib/services/razorpay_service.dart
// This file is the DEFAULT stub — overridden by platform-specific files

class RazorpayService {
  static Future<void> openMobileCheckout({
    required String keyId,
    required String orderId,
    required int amount,
    required String name,
    required String email,
    required String plan,
    required Function(String, String, String) onSuccess,
    required Function(String) onError,
  }) async {
    onError('Not supported on this platform.');
  }

  static Future<void> openWebCheckout({
    required String keyId,
    required String orderId,
    required int amount,
    required String name,
    required String email,
    required String plan,
    required Function(String, String, String) onSuccess,
    required Function(String) onError,
  }) async {
    onError('Not supported on this platform.');
  }
}