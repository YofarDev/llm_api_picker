import 'dart:async';

import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static Future<String> checkFunctionsCalling({
    required String systemPrompt,
    required String modelName,
    required String apiKey,
    required List<Content> content,
    required String prompt,
    double? temperature,
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
      systemInstruction: Content.system(systemPrompt),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: temperature,
      ),
    );
    final List<Content> c = <Content>[
      ...content,
      Content.text(prompt),
    ];
    final GenerateContentResponse response = await model.generateContent(
      c,
    );
    return response.text ?? '';
  }

  static Future<String> promptModel({
    required String apiKey, // add Bearer for most of the APIs
    required String modelName,
    required List<Content> content,
    String? systemPrompt,
    bool returnJson = false,
    double? temperature,
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
      generationConfig: GenerationConfig(
        responseMimeType: returnJson ? 'application/json' : null,
        temperature: temperature,
      ),
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
    double? temperature,
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
      generationConfig: GenerationConfig(
        responseMimeType: returnJson ? 'application/json' : null,
        temperature: temperature,
      ),
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
