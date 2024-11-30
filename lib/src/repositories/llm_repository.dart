import '../../llm_api_picker.dart';

class LLMRepository {
  static Future<void> saveLlmApi(LlmApi llmApi) async {
    await CacheService.updateSavedList(
      LlmApi(
        name: llmApi.name,
        url: llmApi.url,
        headerApiKeyEntry: llmApi.headerApiKeyEntry,
        apiKey: llmApi.apiKey,
        modelName: llmApi.modelName,
      ),
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
    required List<Map<String, dynamic>> messages,
  }) async {
    final LlmApi? currentApi = api ?? await CacheService.getCurrentApi();
    if (currentApi == null) throw Exception('No API selected');
    return OpenAIService.promptModel(
      apiUrl: currentApi.url,
      headerApiKeyEntry: currentApi.headerApiKeyEntry,
      apiKey:  currentApi.apiKey,
      modelName: currentApi.modelName,
      messages: messages,
    );
  }
}
