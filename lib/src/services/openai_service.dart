// ignore_for_file: avoid_dynamic_calls

import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenAIService {
  static Future<String> promptModel({
    required String apiUrl,
    String headerApiKeyEntry = 'Authorization',
    required String apiKey, // add Bearer for most of the APIs
    required String modelName,
    required List<Map<String, dynamic>> messages,
  }) async {
    final Map<String, String> headers = <String, String>{
      headerApiKeyEntry:
          headerApiKeyEntry == 'Authorization' ? 'Bearer $apiKey' : apiKey,
      'Content-Type': 'application/json',
    };
    final String body = jsonEncode(<String, Object>{
      'messages': messages,
      'model': modelName,
    });
    try {
      final http.Response response =
          await http.post(Uri.parse(apiUrl), headers: headers, body: body);
      if (response.statusCode == 200) {
        final String answer = jsonDecode(response.body)['choices'][0]['message']
            ['content'] as String;
        return answer;
      } else {
        print(response.body);
        final dynamic errorMessage =
            jsonDecode(response.body)['error']['message'] ?? 'Unknown error';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception(e);
    }
  }
}
