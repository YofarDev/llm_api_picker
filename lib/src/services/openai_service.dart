// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenAIService {
  List<Map<String, dynamic>> _conversationHistory = <Map<String, dynamic>>[];
  String? _currentModelName;
  String? _currentApiUrl;
  String? _currentApiKey;

  Future<String> checkFunctionsCalling({
    String? systemPrompt,
    String? modelName,
    required String apiUrl,
    required String apiKey,
    required String prompt,
    bool newConversation = true,
  }) async {
    if (newConversation) {
      _conversationHistory = <Map<String, dynamic>>[];
      _currentModelName = modelName;
      _currentApiUrl = apiUrl;
      _currentApiKey = apiKey;
      if (systemPrompt != null) {
        _conversationHistory
            .add(<String, dynamic>{'role': 'system', 'content': systemPrompt});
      }
    }

    _conversationHistory
        .add(<String, dynamic>{'role': 'user', 'content': prompt});
    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $_currentApiKey',
      'Content-Type': 'application/json',
    };
    final String body = jsonEncode(<String, Object?>{
      'model': _currentModelName,
      'messages': _conversationHistory,
    });
    try {
      final http.Response response = await http.post(
        Uri.parse(_currentApiUrl!),
        headers: headers,
        body: body,
      );
      if (response.statusCode == 200) {
        final String responseText = jsonDecode(response.body)['choices'][0]
            ['message']['content'] as String;
        _conversationHistory.add(
          <String, dynamic>{'role': 'assistant', 'content': responseText},
        );
        return responseText;
      } else {
        final dynamic errorMessage =
            jsonDecode(response.body)['error']['message'] ?? 'Unknown error';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  static Future<String> promptModel({
    required String apiUrl,
    required String apiKey, // add Bearer for most of the APIs
    required String modelName,
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
  }) async {
    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
    if (systemPrompt != null) {
      messages.insert(
        0,
        <String, dynamic>{'role': 'system', 'content': systemPrompt},
      );
    }
    final String body = jsonEncode(<String, Object>{
      'model': modelName,
      'messages': messages,
    });
    try {
      final http.Response response =
          await http.post(Uri.parse(apiUrl), headers: headers, body: body);
      if (response.statusCode == 200) {
        final String answer = jsonDecode(response.body)['choices'][0]['message']
            ['content'] as String;
        return answer;
      } else {
        final dynamic errorMessage =
            jsonDecode(response.body)['error']['message'] ?? 'Unknown error';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception(e);
    }
  }
}
