import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../models/function_info.dart';

class GeminiService {
  static Future<List<FunctionInfo>> checkFunctionsCalling({
    required String systemPrompt,
    required String modelName,
    required String apiKey,
    required String prompt,
    required List<FunctionInfo> functions,
  }) async {

    final GenerativeModel model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      safetySettings: <SafetySetting>[
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
      ],
      systemInstruction: Content.system(systemPrompt),
    );
    final GenerateContentResponse response =
        await model.generateContent(<Content>[Content.text(prompt)]);
    final dynamic json = jsonDecode(response.text ?? '');
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
  }

  static Future<String> promptModel({
    required String apiKey, // add Bearer for most of the APIs
    required String modelName,
    required List<Content> content,
    String? systemPrompt,
    bool returnJson = false,
  }) async {
    final GenerativeModel model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      safetySettings: <SafetySetting>[
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
      ],
      systemInstruction:
          systemPrompt != null ? Content.system(systemPrompt) : null,
      generationConfig: returnJson
          ? GenerationConfig(responseMimeType: 'application/json')
          : null,
    );
    final GenerateContentResponse response =
        await model.generateContent(content);
    return response.text ?? '';
  }
}
