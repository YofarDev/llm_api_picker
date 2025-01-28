import 'dart:async';

import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  late ChatSession _functionsChat;

  Future<String> checkFunctionsCalling({
    String? systemPrompt,
    String? modelName,
    String? apiKey,
    required String prompt,
    bool newConversation = true,
  }) async {
    if (newConversation) {
      final GenerativeModel model = GenerativeModel(
        model: modelName!,
        apiKey: apiKey!,
        generationConfig:
            GenerationConfig(responseMimeType: 'application/json'),
        safetySettings: <SafetySetting>[
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        ],
        systemInstruction: Content.system(systemPrompt!),
      );
      _functionsChat = model.startChat();
    }
    final GenerateContentResponse response = await _functionsChat.sendMessage(
      Content.text(prompt),
    );
    return response.text ?? '';
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

  static Stream<String> promptModelStream({
    required String apiKey,
    required String modelName,
    required List<Content> content,
    String? systemPrompt,
    bool returnJson = false,
  }) async* {
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
    final Stream<GenerateContentResponse> responses =
        model.generateContentStream(content);
    await for (final GenerateContentResponse chunk in responses) {
      if (chunk.text != null) {
        yield chunk.text!;
      }
    }
  }
}
