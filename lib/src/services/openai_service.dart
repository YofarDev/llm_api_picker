// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/extensions.dart';

class OpenAIService {
  static Future<String> checkFunctionsCalling({
    required String systemPrompt,
    required String modelName,
    required String apiUrl,
    required String apiKey,
    required List<Map<String, dynamic>> messages,
    required String prompt,
    bool newConversation = true,
    double? temperature,
  }) async {
    messages.add(
      <String, dynamic>{'role': 'user', 'content': prompt},
    );
    final String responseText = await _sendRequest(
      apiUrl,
      apiKey,
      modelName,
      messages,
      returnJson: true,
      temperature: temperature,
    );
    return responseText;
  }

  static Future<String> promptModel({
    required String apiUrl,
    required String apiKey,
    required String modelName,
    required List<Map<String, dynamic>> messages,
    String? systemPrompt,
    bool returnJson = false,
    double? temperature,
  }) {
    if (systemPrompt != null) {
      messages.insert(
        0,
        <String, dynamic>{'role': 'system', 'content': systemPrompt},
      );
    }
    final String url = apiUrl.endsWith('/chat/completions')
        ? apiUrl
        : '$apiUrl/chat/completions';
    return _sendRequest(
      url,
      apiKey,
      modelName,
      messages,
      returnJson: returnJson,
    );
  }

  static Future<String> _sendRequest(
    String apiUrl,
    String apiKey,
    String modelName,
    List<Map<String, dynamic>> messages, {
    bool returnJson = false,
    bool stream = false,
    double? temperature,
  }) async {
    try {
      final Map<String, String> headers = <String, String>{
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };
      final String body = jsonEncode(<String, Object>{
        'model': modelName,
        'messages': messages,
        'stream': stream,
        if (temperature != null && temperature > 0) 'temperature': temperature,
        // doesn't seem to work with all APIs
        // if (returnJson)
        //   'response_format': <String, String>{
        //     "type": "json_object",
        //   },
      });

      final http.Response response =
          await http.post(Uri.parse(apiUrl), headers: headers, body: body);

      if (response.statusCode == 200) {
        return _parseResponse(response, returnJson: returnJson);
      } else {
        debugPrint('### Status code ###\n${response.statusCode}');
        _handleErrorResponse(response);
        return '';
      }
    } catch (e) {
      debugPrint('### Error ###\n$e');
      throw Exception(e);
    }
  }

  static Stream<String> promptModelStream({
    required String apiUrl,
    required String apiKey,
    required String modelName,
    required List<Map<String, dynamic>> messages,
    bool returnJson = false,
    bool debugLogs = false,
    double? temperature,
  }) async* {
    try {
      final Map<String, String> headers = <String, String>{
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };
      final String body = jsonEncode(<String, Object>{
        'model': modelName,
        'messages': messages,
        'stream': true,
        if (temperature != null && temperature > 0) 'temperature': temperature,
        if (returnJson)
          'response_format': <String, String>{
            "type": "json_object",
          },
      });
      if (debugLogs) {
        debugPrint(
          '### Request sent to $modelName ###\n${messages.toString().safeSubstring(0, 500)}',
        );
      }
      final String url = apiUrl.endsWith('/chat/completions')
          ? apiUrl
          : '$apiUrl/chat/completions';
      final http.StreamedResponse response = await http.Client().send(
        http.Request('POST', Uri.parse(url))
          ..headers.addAll(headers)
          ..body = body,
      );
      if (response.statusCode == 200) {
        StringBuffer buffer = StringBuffer();
        await for (final String chunk
            in response.stream.transform(utf8.decoder)) {
          buffer.write(chunk);
          while (buffer.toString().contains('\n')) {
            final int index = buffer.toString().indexOf('\n');
            final String line = buffer.toString().substring(0, index);
            buffer = StringBuffer(buffer.toString().substring(index + 1));
            if (line.trim().isEmpty) continue;
            if (!line.startsWith('data: ')) continue;
            final String jsonStr = line.substring(6).trim();
            if (jsonStr == '[DONE]') break;
            try {
              final Map<String, dynamic> json =
                  jsonDecode(jsonStr) as Map<String, dynamic>;
              final String? content =
                  json['choices']?[0]?['delta']?['content'] as String?;

              if (content != null && content.isNotEmpty) {
                yield content;
              }
            } catch (e) {
              if (debugLogs) {
                debugPrint('### Error parsing JSON ###\n$e');
                debugPrint('Problematic JSON string: $jsonStr');
              }
              continue;
            }
          }
        }
        // Handle any remaining content in the buffer
        if (buffer.isNotEmpty && debugLogs) {
          debugPrint('Remaining buffer: $buffer');
        }
      } else {
        _handleErrorResponse(await http.Response.fromStream(response));
      }
    } catch (e) {
      if (debugLogs) {
        debugPrint('### Error ###\n$e');
      }
      throw Exception(e);
    }
  }

  static String _ensureJsonString(String input) {
    final int startIndex = input.indexOf('{');
    final int endIndex = input.lastIndexOf('}') + 1;
    return input.substring(startIndex, endIndex);
  }

  static String _parseResponse(
    http.Response response, {
    required bool returnJson,
  }) {
    final Map<String, dynamic> decodedBody =
        jsonDecode(utf8.decode(response.bodyBytes).replaceAll('\n', ''))
            as Map<String, dynamic>;
    debugPrint(decodedBody.toString());
    final dynamic content = decodedBody['choices'][0]['message']['content'];
    final String formatedString = formatContent(content);
    if (returnJson) {
      return _ensureJsonString(formatedString);
    } else {
      return formatedString;
    }
  }

  static String formatContent(dynamic content) {
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
