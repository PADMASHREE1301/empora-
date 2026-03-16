// lib/services/groq_service.dart
// Calls the Groq API directly from Flutter using llama-3.3-70b-versatile.
// Store your API key in a .env / app config — never hard-code in production.

import 'dart:convert';
import 'package:http/http.dart' as http;

class GroqService {
  // ──────────────────────────────────────────────────────────────────────────
  // IMPORTANT: Replace with your actual GROQ API key.
  // Get a FREE key at: https://console.groq.com → API Keys → Create API Key
  // In production load from dart_dotenv / flutter_secure_storage.
  // ──────────────────────────────────────────────────────────────────────────
  static const String _apiKey = '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'; //
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _model   = 'llama-3.3-70b-versatile';

  /// Sends [prompt] to Groq and returns the assistant message content.
  /// Throws [GroqException] on any error.
  static Future<String> complete(String prompt) async {
    final response = await http
        .post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are an expert startup investor analyst with 20+ years of experience. '
                    'CRITICAL: Respond with ONLY valid JSON — no markdown fences, no explanation text. '
                    'No trailing commas. Your entire response must be parseable by JSON.parse(). '
                    'Always complete the full JSON object — never truncate.',
              },
              {
                'role': 'user',
                'content': prompt,
              }
            ],
            'temperature': 0.2,
            'max_tokens':  2500,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content =
          data['choices']?[0]?['message']?['content'] as String? ?? '';
      if (content.isEmpty) throw GroqException('Empty response from Groq');
      return content;
    } else {
      final err = jsonDecode(response.body);
      throw GroqException(
          'Groq API error ${response.statusCode}: ${err['error']?['message'] ?? response.body}');
    }
  }
}

class GroqException implements Exception {
  final String message;
  const GroqException(this.message);

  @override
  String toString() => 'GroqException: $message';
}