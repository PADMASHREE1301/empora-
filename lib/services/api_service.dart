// lib/services/api_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {

static const String _baseUrl = 'https://empora-ex0f.onrender.com/api';  
  // ── Token helpers ─────────────────────────────────────────────────────────
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await _getToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, dynamic> _decode(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400) {
      throw ApiException(
          body['message'] ?? 'Error ${res.statusCode}', res.statusCode);
    }
    return body;
  }

  // ─── AUTH ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'free',
    String? phone,
    String? company,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name, 'email': email, 'password': password, 'role': role,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (company != null && company.isNotEmpty) 'company': company,
      }),
    );
    final data = _decode(res);
    if (data['token'] != null) await saveToken(data['token']);
    return data;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: await _headers(),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final data = _decode(res);
    if (data['token'] != null) await saveToken(data['token']);
    return data;
  }

  static Future<void> logout() async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: await _headers(),
      );
      _decode(res);
    } finally {
      await clearToken();
    }
  }

  static Future<Map<String, dynamic>> getProfile() async => getMe();

  static Future<Map<String, dynamic>> getMe() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/auth/me'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  // ── Upgrade membership ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> upgradeMembership({
    required String plan,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/upgrade-membership'),
      headers: await _headers(),
      body: jsonEncode({'plan': plan}),
    );
    return _decode(res);
  }

  // ── Admin helpers ─────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> adminGet(String path) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/admin$path'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> adminPatch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/admin$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  // ─── FUNDRAISING ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> createFundRaising({
    required String company,
    required String sector,
    required String fundingGoal,
    String askAmount        = '',
    String businessIdea     = '',
    String problemStatement = '',
    String solution         = '',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/fund/create'),
      headers: await _headers(),
      body: jsonEncode({
        'company': company, 'sector': sector, 'fundingGoal': fundingGoal,
        'askAmount': askAmount, 'businessIdea': businessIdea,
        'problemStatement': problemStatement, 'solution': solution,
      }),
    );
    final data = _decode(res);
    return data['data'] as Map<String, dynamic>;
  }

  static Future<void> updatePitchDeck({
    required String recordId,
    required Map<String, String> fields,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/fund/$recordId/pitch-deck'),
      headers: await _headers(),
      body: jsonEncode(fields),
    );
    _decode(res);
  }

  static Future<Map<String, dynamic>> uploadPitchDeck({
    required String recordId,
    File? file,
    Uint8List? bytes,
    required String fileName,
    required Map<String, String> fields,
  }) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'PUT', Uri.parse('$_baseUrl/fund/$recordId/pitch-deck'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    fields.forEach((k, v) => request.fields[k] = v);
    final mimeType = MediaType.parse(_mimeType(fileName.split('.').last.toLowerCase()));
    if (kIsWeb && bytes != null) {
      request.files.add(http.MultipartFile.fromBytes('pitchFile', bytes, filename: fileName, contentType: mimeType));
    } else if (file != null) {
      request.files.add(await http.MultipartFile.fromPath('pitchFile', file.path, contentType: mimeType));
    }
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res)['data'] as Map<String, dynamic>;
  }

  static Future<void> updateValuation({
    required String recordId,
    required Map<String, String> fields,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/fund/$recordId/valuation'),
      headers: await _headers(),
      body: jsonEncode(fields),
    );
    _decode(res);
  }

  static Future<Map<String, dynamic>> uploadValuation({
    required String recordId,
    File? file,
    Uint8List? bytes,
    required String fileName,
    required Map<String, String> fields,
  }) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'PUT', Uri.parse('$_baseUrl/fund/$recordId/valuation'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    fields.forEach((k, v) => request.fields[k] = v);
    final mimeType = MediaType.parse(_mimeType(fileName.split('.').last.toLowerCase()));
    if (kIsWeb && bytes != null) {
      request.files.add(http.MultipartFile.fromBytes('valuationFile', bytes, filename: fileName, contentType: mimeType));
    } else if (file != null) {
      request.files.add(await http.MultipartFile.fromPath('valuationFile', file.path, contentType: mimeType));
    }
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return _decode(res)['data'] as Map<String, dynamic>;
  }

  static Future<void> updateComments({
    required String recordId,
    required String businessBackground,
    String experience        = '',
    String competitorDetails = '',
    String riskFactors       = '',
    String futurePlan        = '',
    String useOfFunds        = '',
    String traction          = '',
    String stage             = '',
    List<String> investorComments = const [],
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/fund/$recordId/comments'),
      headers: await _headers(),
      body: jsonEncode({
        'businessBackground': businessBackground, 'experience': experience,
        'competitorDetails': competitorDetails, 'riskFactors': riskFactors,
        'futurePlan': futurePlan, 'useOfFunds': useOfFunds,
        'traction': traction, 'stage': stage,
        'investorComments': investorComments,
      }),
    );
    _decode(res);
  }

  static Future<List<dynamic>> getMyFundRaisings() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/fund/my'),
      headers: await _headers(),
    );
    return _decode(res)['data'] as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getExtractedText({
    required String recordId,
  }) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/fund/$recordId/extracted-text'),
      headers: await _headers(),
    );
    return _decode(res)['data'] as Map<String, dynamic>;
  }

  static Future<void> saveFundAiReport({
    required String recordId,
    required Map<String, dynamic> report,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/fund/$recordId/ai-report'),
      headers: await _headers(),
      body: jsonEncode(report),
    );
    _decode(res);
  }

  // ─── GENERIC MODULE API ───────────────────────────────────────────────────

  static Future<Map<String, dynamic>> createModuleRecord({
    required String module,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/$module/create'),
      headers: await _headers(),
    );
    final data = _decode(res);
    return data['data'] as Map<String, dynamic>;
  }

  static Future<void> uploadModuleFile({
    required String module,
    required String recordId,
    required String slotKey,
    File? file,
    Uint8List? bytes,
    required String fileName,
  }) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'PUT', Uri.parse('$_baseUrl/$module/$recordId/upload'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.fields['slotKey'] = slotKey;
    final mimeType = MediaType.parse(_mimeType(fileName.split('.').last.toLowerCase()));
    if (kIsWeb && bytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'moduleFile', bytes, filename: fileName, contentType: mimeType,
      ));
    } else if (file != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'moduleFile', file.path, contentType: mimeType,
      ));
    }
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _decode(res);
  }

  static Future<Map<String, dynamic>> getModuleData({
    required String module,
    required String recordId,
  }) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/$module/$recordId/data'),
      headers: await _headers(),
    );
    return _decode(res)['data'] as Map<String, dynamic>;
  }

  static Future<List<dynamic>> getMyModuleRecords({
    required String module,
  }) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/$module/my'),
      headers: await _headers(),
    );
    return _decode(res)['data'] as List<dynamic>;
  }

  static Future<String?> saveModuleAiReport({
    required String module,
    required String recordId,
    required Map<String, dynamic> report,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/$module/$recordId/ai-report'),
      headers: await _headers(),
      body: jsonEncode(report),
    );
    final body = _decode(res);
    return body['pdfUrl'] as String?;
  }

  static Future<String?> getModulePdfUrl({
    required String module,
    required String recordId,
  }) async {
    try {
      final data     = await getModuleData(module: module, recordId: recordId);
      final aiReport = data['aiReport'] as Map<String, dynamic>?;
      final stored   = aiReport?['pdfUrl'] as String?;
      if (stored != null && stored.isNotEmpty) {
return '$_baseUrl$stored';      }
    } catch (_) {}
return '$_baseUrl/$module/$recordId/report/pdf';  }

  // ─── CHATBOT ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> sendChatMessage({
    required String module,
    required String message,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/chat/$module/message'),
      headers: await _headers(),
      body: jsonEncode({'message': message}),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> getChatHistory({
    required String module,
  }) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/chat/$module/history'),
      headers: await _headers(),
    );
    return _decode(res);
  } 

  static Future<void> clearChatHistory({
    required String module,
  }) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/chat/$module/clear'),
      headers: await _headers(),
    );
    _decode(res);
  }

  // ─── Legacy ───────────────────────────────────────────────────────────────
  static Future<void> uploadComments({
    required String recordId,
    File? file,
    Uint8List? bytes,
    required String fileName,
    Map<String, String> fields = const {},
  }) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'PUT', Uri.parse('$_baseUrl/fund/$recordId/comments'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    fields.forEach((k, v) => request.fields[k] = v);
    final mimeType = MediaType.parse(_mimeType(fileName.split('.').last.toLowerCase()));
    if (kIsWeb && bytes != null) {
      request.files.add(http.MultipartFile.fromBytes('commentsFile', bytes, filename: fileName, contentType: mimeType));
    } else if (file != null) {
      request.files.add(await http.MultipartFile.fromPath('commentsFile', file.path, contentType: mimeType));
    }
    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    _decode(res);
  }
  // ─── Pricing ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getPublicPricing() async {
    final res = await http.get(Uri.parse('$_baseUrl/payment/pricing'));
    return _decode(res);
  }

  static Future<Map<String, dynamic>> getAdminPricing() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/admin/pricing'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> updatePricing({
    required int monthly,
    required int yearly,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/admin/pricing'),
      headers: await _headers(),
      body: jsonEncode({'monthly': monthly, 'yearly': yearly}),
    );
    return _decode(res);
  }

  // ─── Payment ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> createPaymentOrder({
    required String plan,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/payment/create-order'),
      headers: await _headers(),
      body: jsonEncode({'plan': plan}),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> verifyPayment({
    required String orderId,
    required String paymentId,
    required String signature,
    required String plan,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/payment/verify'),
      headers: await _headers(),
      body: jsonEncode({
        'razorpay_order_id':   orderId,
        'razorpay_payment_id': paymentId,
        'razorpay_signature':  signature,
        'plan':                plan,
      }),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> getPaymentStatus() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/payment/status'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  // ─── Founder Profile ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> saveFounderProfile(
      Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/auth/founder-profile'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return _decode(res);
  }

  static Future<Map<String, dynamic>> getFounderProfile() async {
    final res = await http.get(
      Uri.parse('$_baseUrl/auth/founder-profile'),
      headers: await _headers(),
    );
    return _decode(res);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  static String _mimeType(String ext) {
    switch (ext) {
      case 'pdf':  return 'application/pdf';
      case 'ppt':  return 'application/vnd.ms-powerpoint';
      case 'pptx': return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'doc':  return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':  return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'png':  return 'image/png';
      default:     return 'application/octet-stream';
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  const ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException $statusCode: $message';
}