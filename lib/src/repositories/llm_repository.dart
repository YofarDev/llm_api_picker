import 'package:flutter/services.dart';

import '../../llm_api_picker.dart';

class LLMRepository {
  static Future<void> saveLlmApi(LlmApi llmApi) async {
    await CacheService.updateSavedList(
      llmApi,
    );
  }

  static Future<void> deleteLlmApi(LlmApi llmApi) async {
    await CacheService.deleteEntryList(llmApi);
  }

  static Future<List<LlmApi>> getSavedLlmApis() async {
    return CacheService.getSavedLlmApis();
  }

  static Future<void> updateExistingLlmApi(LlmApi llmApi) async {
    await CacheService.updateExistingEntry(llmApi);
  }

  static Future<void> setCurrentApi(LlmApi llmApi) async {
    await CacheService.setCurrentApi(llmApi);
  }

  static Future<LlmApi?> getCurrentApi() async {
    return CacheService.getCurrentApi();
  }

  static Future<String> promptModel({
    LlmApi? api,
    required List<Message> messages,
    String? systemPrompt,
    bool returnJson = false,
  }) async {
    final LlmApi? currentApi = api ?? await CacheService.getCurrentApi();
    if (currentApi == null) throw Exception('No API selected');
    return currentApi.isGemini
        ? GeminiService.promptModel(
            apiKey: currentApi.apiKey,
            modelName: currentApi.modelName,
            content: await messages.toGeminiMessages(),
            systemPrompt: systemPrompt,
            returnJson: returnJson,
          )
        : OpenAIService.promptModel(
            apiUrl: currentApi.url,
            apiKey: currentApi.apiKey,
            modelName: currentApi.modelName,
            messages: await messages.toOpenAiMessages(),
            systemPrompt: systemPrompt,
          );
  }

  static Future<List<FunctionInfo>> checkFunctionsCalling({
    LlmApi? api,
    required String lastUserMessage,
    required List<FunctionInfo> functions,
  }) async {
    final LlmApi? currentApi = api ?? await CacheService.getCurrentApi();
    if (currentApi == null) throw Exception('No API selected');
    final String systemPrompt = (await rootBundle.loadString(
      'packages/llm_api_picker/lib/assets/functions_calling_prompt.txt',
    ))
        .replaceAll('\$FUNCTIONS_LIST', functions.toPromptString());
    return currentApi.isGemini
        ? GeminiService.checkFunctionsCalling(
            systemPrompt: systemPrompt,
            modelName: currentApi.modelName,
            apiKey: currentApi.apiKey,
            prompt: lastUserMessage,
            functions: functions,
          )
        : OpenAIService.checkFunctionsCalling(
            systemPrompt: systemPrompt,
            apiUrl: currentApi.url,
            apiKey: currentApi.apiKey,
            modelName: currentApi.modelName,
            prompt: lastUserMessage,
            functions: functions,
          );
  }
}
