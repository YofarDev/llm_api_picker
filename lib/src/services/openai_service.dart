// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../llm_api_picker.dart';

class OpenAIService {
  static Future<List<FunctionInfo>> checkFunctionsCalling({
    required String systemPrompt,
    required String modelName,
    required String apiUrl,
    required String apiKey,
    required String prompt,
    required List<FunctionInfo> functions,
  }) async {
    final Map<String, String> headers = <String, String>{
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
    final List<Map<String, dynamic>> messages = <Map<String, dynamic>>[
      <String, dynamic>{'role': 'system', 'content': systemPrompt},
      <String, dynamic>{'role': 'user', 'content': prompt},
    ];
    final String body = jsonEncode(<String, Object>{
      'model': modelName,
      'messages': messages,
    });
    try {
      final http.Response response =
          await http.post(Uri.parse(apiUrl), headers: headers, body: body);
      if (response.statusCode == 200) {
        final String jsonString = jsonDecode(response.body)['choices'][0]
            ['message']['content'] as String;
        final dynamic json = jsonDecode(jsonString);
        final List<String> functionsNames =
            functions.map((FunctionInfo e) => e.name).toList();
        final List<FunctionInfo> functionsCalled = <FunctionInfo>[];
        if (json is Map<String, dynamic>) {
          if (json['function'] == null ||
              json['function'] == 'null' ||
              !functionsNames.contains(json['function'])) {
            return <FunctionInfo>[];
          } else {
            final FunctionInfo functionInfo = functions.firstWhere(
              (FunctionInfo e) => e.name == json['function'],
            );
            functionsCalled.add(
              functionInfo.copyWith(
                parameters: json['parameters'] as Map<String, dynamic>?,
              ),
            );
          }
        } else if (json is List) {
          if (json.isEmpty) {
            return <FunctionInfo>[];
          } else {
            for (final dynamic entry in json) {
              if (functionsNames
                  .contains((entry as Map<String, dynamic>)['function'])) {
                final FunctionInfo functionInfo = functions.firstWhere(
                  (FunctionInfo e) => e.name == entry['function'],
                );
                functionsCalled.add(
                  functionInfo.copyWith(
                    parameters: entry['parameters'] as Map<String, dynamic>?,
                  ),
                );
              }
            }
          }
        }
        return functionsCalled;
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
