// lib/services/razorpay_stub.dart
// Web stub for razorpay_flutter — used on web platform via conditional import:
// import 'package:razorpay_flutter/razorpay_flutter.dart'
//     if (dart.library.html) 'package:empora/services/razorpay_stub.dart';

class PaymentSuccessResponse {
  final String? paymentId;
  final String? orderId;
  final String? signature;
  const PaymentSuccessResponse({this.paymentId, this.orderId, this.signature});
}

class PaymentFailureResponse {
  final int? code;
  final String? message;
  const PaymentFailureResponse({this.code, this.message});
}

class ExternalWalletResponse {
  final String? walletName;
  const ExternalWalletResponse({this.walletName});
}

class Razorpay {
  static const String EVENT_PAYMENT_SUCCESS = 'payment.success';
  static const String EVENT_PAYMENT_ERROR   = 'payment.error';
  static const String EVENT_EXTERNAL_WALLET = 'payment.external_wallet';

  void on(String event, Function handler) {}
  void open(Map<String, dynamic> options) {}
  void clear() {}
}