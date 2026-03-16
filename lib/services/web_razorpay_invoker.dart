// lib/services/web_razorpay_invoker.dart
// MOBILE / DEFAULT stub — no dart:js, no dart:html

class WebRazorpayInvoker {
  static void open({
    required String keyId,
    required String orderId,
    required int amount,
    required String name,
    required String email,
    required String plan,
    required Function(String, String, String) onSuccess,
    required Function(String) onError,
  }) {
    // Does nothing on mobile — Razorpay SDK handles it directly
  }
}