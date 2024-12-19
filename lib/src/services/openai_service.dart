// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:flutter/foundation.dart';
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
      _initializeConversation(systemPrompt, modelName, apiUrl, apiKey);
    } else {
      _conversationHistory.removeLast();
    }
    _conversationHistory
        .add(<String, dynamic>{'role': 'user', 'content': prompt});
    debugPrint(_conversationHistory.toString());
    final String responseText = await _sendRequest(
      _currentApiUrl!,
      _currentApiKey!,
      _currentModelName!,
      _conversationHistory,
      returnJson: true,
    );
    // _conversationHistory.add(
    //   <String, dynamic>{'role': 'assistant', 'content': responseText},
    // );
    return responseText;
  }

  static Future<String> promptModel({
    required String apiUrl,
    required String apiKey,
    required String modelName,
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
    bool returnJson = false,
  }) async {
    if (systemPrompt != null) {
      messages.insert(
        0,
        <String, dynamic>{'role': 'system', 'content': systemPrompt},
      );
    }

    return _sendRequest(
      apiUrl,
      apiKey,
      modelName,
      messages,
      returnJson: returnJson,
    );
  }

  void _initializeConversation(
    String? systemPrompt,
    String? modelName,
    String apiUrl,
    String apiKey,
  ) {
    _conversationHistory = <Map<String, dynamic>>[];
    _currentModelName = modelName;
    _currentApiUrl = apiUrl;
    _currentApiKey = apiKey;
    if (systemPrompt != null) {
      _conversationHistory
          .add(<String, dynamic>{'role': 'system', 'content': systemPrompt});
    }
  }

  static Future<String> _sendRequest(
    String apiUrl,
    String apiKey,
    String modelName,
    List<Map<String, dynamic>> messages, {
    bool returnJson = false,
  }) async {
    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };

    final String body = jsonEncode(<String, Object>{
      'model': modelName,
      'messages': messages,
      if (returnJson)
        'response_format': <String, String>{
          "type": "json_object",
        },
    });

    try {
      final http.Response response =
          await http.post(Uri.parse(apiUrl), headers: headers, body: body);

      if (response.statusCode == 200) {
        return _parseResponse(response);
      } else {
        _handleErrorResponse(response);
        return '';
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  static String _parseResponse(http.Response response) {
    final Map<String, dynamic> decodedBody =
        jsonDecode(utf8.decode(response.bodyBytes).replaceAll('\n', ''))
            as Map<String, dynamic>;
    debugPrint(decodedBody.toString());
    final dynamic content = decodedBody['choices'][0]['message']['content'];
    return _formatContent(content);
  }

  static String _formatContent(dynamic content) {
    if (content is String) {
      return content;
    } else if (content is List) {
      return content.join(' ');
    } else {
      return content.toString();
    }
  }

  static void _handleErrorResponse(http.Response response) {
    final dynamic errorMessage =
        jsonDecode(response.body)['error']['message'] ?? 'Unknown error';
    throw Exception(errorMessage);
  }
}
