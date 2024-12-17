import 'dart:convert';

import 'package:flutter/services.dart';

import '../../llm_api_picker.dart';

class LLMRepository {
  late GeminiService _geminiService;
  late OpenAIService _openAIService;

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

  Future<(String, List<FunctionInfo>)> checkFunctionsCalling({
    LlmApi? api,
    required String lastUserMessage,
    required List<FunctionInfo> functions,
    String? previousResponse,
    String? previousResults,
  }) async {
    final LlmApi? currentApi = api ?? await CacheService.getCurrentApi();
    if (currentApi == null) throw Exception('No API selected');
    String? systemPrompt;
    if (previousResponse == null && previousResults == null) {
      _geminiService = GeminiService();
      _openAIService = OpenAIService();
      systemPrompt = (await rootBundle.loadString(
        'packages/llm_api_picker/lib/assets/functions_calling_prompt.txt',
      ))
          .replaceAll('\$FUNCTIONS_LIST', functions.toPromptString())
          .replaceAll(
            '\$MULTISTEP_FUNCTIONS',
            '',
          );
    }
    String prompt = 'Original user’s message : $lastUserMessage';
    if (previousResponse != null && previousResults != null) {
      prompt += '\nPrevious Skynet’s response: $previousResponse';
      prompt += '\nPrevious results to use : $previousResults';
      prompt += '\nFunctions to call: ${functions.toPromptString()}';
    }
    final String response = await (currentApi.isGemini
        ? _geminiService.checkFunctionsCalling(
            systemPrompt: systemPrompt,
            modelName: currentApi.modelName,
            apiKey: currentApi.apiKey,
            prompt: prompt,
            newConversation: previousResponse == null,
          )
        : _openAIService.checkFunctionsCalling(
            systemPrompt: systemPrompt,
            apiUrl: currentApi.url,
            apiKey: currentApi.apiKey,
            modelName: currentApi.modelName,
            prompt: prompt,
          ));
    final List<FunctionInfo> functionsCalled =
        _parseResponseToFunctions(response, functions);
    return (response, functionsCalled);
  }

  static List<FunctionInfo> _parseResponseToFunctions(
    String response,
    List<FunctionInfo> functions,
  ) {
    final dynamic json = jsonDecode(response);
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
}
