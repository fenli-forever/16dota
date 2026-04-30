import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExternalAiConfig {
  static const _keyBaseUrl = 'ai_ext_base_url';
  static const _keyApiKey = 'ai_ext_api_key';
  static const _keyModel = 'ai_ext_model';

  String baseUrl;
  String apiKey;
  String model;

  ExternalAiConfig({
    this.baseUrl = '',
    this.apiKey = '',
    this.model = '',
  });

  bool get isConfigured => baseUrl.isNotEmpty && apiKey.isNotEmpty && model.isNotEmpty;

  static Future<ExternalAiConfig> load() async {
    final sp = await SharedPreferences.getInstance();
    return ExternalAiConfig(
      baseUrl: sp.getString(_keyBaseUrl) ?? '',
      apiKey: sp.getString(_keyApiKey) ?? '',
      model: sp.getString(_keyModel) ?? '',
    );
  }

  Future<void> save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_keyBaseUrl, baseUrl);
    await sp.setString(_keyApiKey, apiKey);
    await sp.setString(_keyModel, model);
  }
}

class ExternalAiService {
  static Dio? _dio;

  static Dio _getDio(String baseUrl, String apiKey) {
    _dio ??= Dio();
    _dio!.options = BaseOptions(
      baseUrl: baseUrl.endsWith('/') ? baseUrl : '$baseUrl/',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
    );
    return _dio!;
  }

  static Future<String> chat({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String prompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    final dio = _getDio(baseUrl, apiKey);

    // Try chat completions endpoint first
    final url = baseUrl.contains('/v1/') || baseUrl.endsWith('/v1')
        ? 'chat/completions'
        : 'v1/chat/completions';

    final resp = await dio.post(url, data: {
      'model': model,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    final data = resp.data as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('API 返回无内容');
    }
    final message = choices[0]['message'];
    final content = message?['content'] as String? ?? '';
    if (content.isEmpty) throw Exception('API 返回内容为空');
    return content.trim();
  }

  static Future<String> chatWithSystem({
    required String baseUrl,
    required String apiKey,
    required String model,
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    final dio = _getDio(baseUrl, apiKey);

    final url = baseUrl.contains('/v1/') || baseUrl.endsWith('/v1')
        ? 'chat/completions'
        : 'v1/chat/completions';

    final resp = await dio.post(url, data: {
      'model': model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    final data = resp.data as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('API 返回无内容');
    }
    final message = choices[0]['message'];
    final content = message?['content'] as String? ?? '';
    if (content.isEmpty) throw Exception('API 返回内容为空');
    return content.trim();
  }

  static Future<String> chatMultiTurn({
    required String baseUrl,
    required String apiKey,
    required String model,
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 2048,
  }) async {
    final dio = _getDio(baseUrl, apiKey);

    final url = baseUrl.contains('/v1/') || baseUrl.endsWith('/v1')
        ? 'chat/completions'
        : 'v1/chat/completions';

    final resp = await dio.post(url, data: {
      'model': model,
      'messages': messages,
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    final data = resp.data as Map<String, dynamic>;
    final choices = data['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('API 返回无内容');
    }
    final message = choices[0]['message'];
    final content = message?['content'] as String? ?? '';
    if (content.isEmpty) throw Exception('API 返回内容为空');
    return content.trim();
  }

  static void resetClient() {
    _dio = null;
  }
}
