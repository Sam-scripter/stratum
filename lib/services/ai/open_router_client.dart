import 'dart:convert';
import 'package:http/http.dart' as http;

/// OpenRouter API client (OpenAI-compatible chat completions).
class OpenRouterClient {
  OpenRouterClient({required this.apiKey});

  final String apiKey;
  static const _baseUrl = 'https://openrouter.ai/api/v1/chat/completions';

  /// Model to use. OpenRouter supports many; e.g. openai/gpt-4o, google/gemini-2.0-flash-exp
  static const String defaultModel = 'openai/gpt-4o';

  /// Single prompt, no history. Returns the model's reply text.
  Future<String> generateContent(String prompt) async {
    return generateChat([
      {'role': 'user', 'content': prompt}
    ]);
  }

  /// Max tokens to request (keeps usage within free-tier limits; avoid default 16384).
  static const int maxTokens = 2048;

  /// Chat with a list of messages. Each map: {"role": "user"|"assistant"|"system", "content": "..."}.
  /// Returns the assistant's reply text.
  Future<String> generateChat(List<Map<String, String>> messages) async {
    final body = {
      'model': defaultModel,
      'messages': messages,
      'stream': false,
      'max_tokens': maxTokens,
    };

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://stratum.app',
        'X-Title': 'Stratum',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      final body = response.body;
      final err = body.isNotEmpty ? body : 'HTTP ${response.statusCode}';
      throw Exception(err);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('No choices in OpenRouter response');
    }
    final first = choices.first as Map<String, dynamic>;
    final message = first['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    return content?.trim() ?? '';
  }
}
