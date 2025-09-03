import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../llm_api_picker.dart';
import '../utils/extensions.dart';

class LLMRepository {
  static Future<void> saveLlmApi(LlmApi llmApi) async {
    await CacheService.updateSavedList(
      llmApi,
    );
  }

  static Future<void> deleteLlmApi(LlmApi llmApi) async {
    await CacheService.deleteEntryList(llmApi);
  }

  static Future<List<LlmApi>> getSavedLlmApis() {
    return CacheService.getSavedLlmApis();
  }

  static Future<void> updateExistingLlmApi(LlmApi llmApi) async {
    await CacheService.updateExistingEntry(llmApi);
  }

  static Future<void> setCurrentApi(LlmApi llmApi) async {
    await CacheService.setCurrentApi(llmApi);
  }

  static Future<LlmApi?> getCurrentApi() {
    return CacheService.getCurrentApi();
  }

  static Future<void> setCurrentSmallApi(LlmApi llmApi) async {
    await CacheService.setCurrentSmallApi(llmApi);
  }

  static Future<LlmApi?> getCurrentSmallApi() {
    return CacheService.getCurrentSmallApi();
  }

  static Future<void> _waitBetweenRequests(LlmApi api) async {
    if (api.millisecondsDelayBetweenRequests > 0) {
      final DateTime? lastRequestTime =
          await CacheService.getLastRequestTime(api.modelName);
      if (lastRequestTime != null) {
        final Duration difference = DateTime.now().difference(lastRequestTime);
        if (difference.inMilliseconds < api.millisecondsDelayBetweenRequests) {
          await Future<void>.delayed(
            Duration(
              milliseconds: api.millisecondsDelayBetweenRequests -
                  difference.inMilliseconds,
            ),
          );
        }
      }
    }
    await CacheService.setLastRequestTime(api.modelName);
  }

  /// Sends a prompt to a language model and returns the response as a String.
  ///
  /// [api] - The API to use for the request. If not provided, the function will use the default API
  ///         or the small API based on the [useSmallApi] flag.
  ///
  /// [messages] - A list of messages to send to the language model. Each message should be an instance
  ///              of the [Message] class.
  ///
  /// [systemPrompt] - An optional system prompt that can be used to guide the model's behavior.
  ///
  /// [returnJson] - If `true`, the function will return the response in JSON format. Defaults to `false`.
  ///
  /// [debugLogs] - If `true`, debug logs will be enabled for the request. Defaults to `false`.
  ///
  /// [useSmallApi] - If `true`, the function will use the small API if no API is provided.
  static Future<String> promptModel({
    LlmApi? api,
    required List<Message> messages,
    String? systemPrompt,
    bool returnJson = false,
    bool debugLogs = false,
    bool useSmallApi = false,
    double? temperature,
  }) async {
    final LlmApi? currentApi = api ??
        (useSmallApi
            ? await CacheService.getCurrentSmallApi()
            : await CacheService.getCurrentApi());
    if (currentApi == null) throw Exception('No API selected');
    await _waitBetweenRequests(currentApi);
    if (debugLogs) {
      debugPrint(
        '### Request sent to ${api!.modelName} ###\n${messages.toString().safeSubstring(0, 500)}',
      );
    }
    return currentApi.isGemini
        ? GeminiService.promptModel(
            apiKey: currentApi.apiKey,
            modelName: currentApi.modelName,
            content: await messages.toGeminiMessages(),
            systemPrompt: systemPrompt,
            returnJson: returnJson,
            temperature: temperature,
          )
        : OpenAIService.promptModel(
            apiUrl: currentApi.url,
            apiKey: currentApi.apiKey,
            modelName: currentApi.modelName,
            messages: await messages.toOpenAiMessages(),
            systemPrompt: systemPrompt,
            returnJson: returnJson,
            temperature: temperature,
          );
  }

  /// Sends a prompt to a language model and returns the response as a Stream(String)
  ///
  /// [api] - The API to use for the request. If not provided, the function will use the default API
  ///         or the small API based on the [useSmallApi] flag.
  ///
  /// [messages] - A list of messages to send to the language model. Each message should be an instance
  ///              of the [Message] class.
  ///
  /// [systemPrompt] - An optional system prompt that can be used to guide the model's behavior.
  ///
  /// [returnJson] - If `true`, the function will return the response in JSON format. Defaults to `false`.
  ///
  /// [debugLogs] - If `true`, debug logs will be enabled for the request. Defaults to `false`.
  ///
  /// [useSmallApi] - If `true`, the function will use the small API if no API is provided.
  static Future<Stream<String>> promptModelStream({
    LlmApi? api,
    required List<Message> messages,
    String? systemPrompt,
    bool returnJson = false,
    bool debugLogs = false,
    bool useSmallApi = false,
    double? temperature,
  }) async {
    final LlmApi? currentApi = api ??
        (useSmallApi
            ? await CacheService.getCurrentSmallApi()
            : await CacheService.getCurrentApi());
    if (currentApi == null) throw Exception('No API selected');
    await _waitBetweenRequests(currentApi);
    if (debugLogs) {
      debugPrint(
        '### Request sent to ${api!.modelName} ###\n${messages.toString().safeSubstring(0, 500)}',
      );
    }
    if (currentApi.isGemini) {
      return GeminiService.promptModelStream(
        apiKey: currentApi.apiKey,
        modelName: currentApi.modelName,
        content: await messages.toGeminiMessages(),
        systemPrompt: systemPrompt,
        returnJson: returnJson,
        temperature: temperature,
      );
    } else {
      final List<Map<String, dynamic>> openAiMessages =
          await messages.toOpenAiMessages();
      if (systemPrompt != null) {
        openAiMessages.insert(
          0,
          <String, dynamic>{'role': 'system', 'content': systemPrompt},
        );
      }
      return OpenAIService.promptModelStream(
        apiUrl: currentApi.url,
        apiKey: currentApi.apiKey,
        modelName: currentApi.modelName,
        messages: openAiMessages,
        returnJson: returnJson,
        debugLogs: debugLogs,
        temperature: temperature,
      );
    }
  }

  /// This function takes a user's message and a list of functions to call,
  /// and uses the language model to generate code that calls the functions.
  ///
  /// The function takes the following parameters:
  ///
  /// [api] - The API to use to make the request. If not provided, the
  ///         function will use the default API or the small API based on the
  ///         [useSmallApi] flag.
  ///
  /// [lastUserMessage] - The user's message that triggered the code generation.
  ///
  /// [functions] - A list of functions to call. The functions must be in the
  ///               format of [FunctionInfo] objects.
  /// [useSmallApi] - If `true`, the function will use the small API if no API
  ///                 is provided. Defaults to `false`.
  ///
  /// The function returns a tuple containing the response from the language
  /// model and a list of functions that were called by the generated code.
  Future<(String, List<FunctionInfo>)> checkFunctionsCalling({
    LlmApi? api,
    required List<Message> messages,
    required String lastUserMessage,
    required List<FunctionInfo> functions,
    bool useSmallApi = true,
    double? temperature,
  }) async {
    final LlmApi? currentApi = api ??
        (useSmallApi
            ? await CacheService.getCurrentSmallApi()
            : await CacheService.getCurrentApi());
    if (currentApi == null) throw Exception('No API selected');
    String? systemPrompt;
    systemPrompt = (await rootBundle.loadString(
      'packages/llm_api_picker/lib/assets/functions_calling_prompt.txt',
    ))
        .replaceAll('\$FUNCTIONS_LIST', functions.toPromptString());
    final String prompt =
        'Analyze the following user message and determine if a function call is needed:\n"""$lastUserMessage"""\nYou can use previous messages for context if needed. Respond in JSON format with functions to call, and {"function": null} if none are needed.';
    await _waitBetweenRequests(currentApi);
    final String response = await (currentApi.isGemini
        ? GeminiService.checkFunctionsCalling(
            systemPrompt: systemPrompt,
            modelName: currentApi.modelName,
            apiKey: currentApi.apiKey,
            content: await messages.toGeminiMessages(),
            prompt: prompt,
            temperature: temperature,
          )
        : OpenAIService.checkFunctionsCalling(
            systemPrompt: systemPrompt,
            apiUrl: currentApi.url,
            apiKey: currentApi.apiKey,
            modelName: currentApi.modelName,
            messages: await messages.toOpenAiMessages(),
            prompt: prompt,
            temperature: temperature,
          ));
    final List<FunctionInfo> functionsCalled =
        _parseResponseToFunctions(response, functions);
    return (response, functionsCalled);
  }

  /// This function takes a user's conversation and a list of functions to call,
  /// and uses the language model to generate code that calls the functions.
  ///
  /// The function takes the following parameters:
  ///
  /// [api] - The API to use to make the request. If not provided, the
  ///         function will use the default API or the small API based on the
  ///         [useSmallApi] flag.
  ///
  /// [lastUserMessage] - The user's message that triggered the code generation.
  ///
  /// [functions] - A list of functions to call. The functions must be in the
  ///               format of [FunctionInfo] objects.
  ///
  /// [previousResponse] - If the code generation is a follow-up to a previous
  ///                      generation, this is the response from the previous
  ///                      generation.
  ///
  /// [previousResults] - If the code generation is a follow-up to a previous
  ///                     generation, this is the results from the previous
  ///                     generation.
  ///
  /// [useSmallApi] - If `true`, the function will use the small API if no API
  ///                 is provided. Defaults to `false`.
  ///
  /// The function returns a tuple containing the response from the language
  /// model and a list of functions that were called by the generated code.
  Future<(String, List<FunctionInfo>)> checkFunctionsCallingMultisteps({
    LlmApi? api,
    required List<Message> messages,
    required String lastUserMessage,
    required List<FunctionInfo> functions,
    String? previousResponse,
    String? previousResults,
    bool useSmallApi = true,
    double? temperature,
  }) async {
    final LlmApi? currentApi = api ??
        (useSmallApi
            ? await CacheService.getCurrentSmallApi()
            : await CacheService.getCurrentApi());
    if (currentApi == null) throw Exception('No API selected');
    String? systemPrompt;
    systemPrompt = (await rootBundle.loadString(
      'packages/llm_api_picker/lib/assets/functions_calling_prompt_multi.txt',
    ))
        .replaceAll('\$FUNCTIONS_LIST', functions.toPromptString())
        .replaceAll(
          '\$MULTISTEP_FUNCTIONS',
          '',
        );
    String prompt = 'Original user’s message : $lastUserMessage';
    if (previousResponse != null && previousResults != null) {
      prompt += '\nPrevious Skynet’s response: $previousResponse';
      prompt += '\nPrevious results to use : $previousResults';
      prompt += '\nFunctions to call: ${functions.toPromptString()}';
    }
    await _waitBetweenRequests(currentApi);
    final String response = await (currentApi.isGemini
        ? GeminiService.checkFunctionsCalling(
            systemPrompt: systemPrompt,
            modelName: currentApi.modelName,
            apiKey: currentApi.apiKey,
            content: await messages.toGeminiMessages(),
            prompt: prompt,
            temperature: temperature,
          )
        : OpenAIService.checkFunctionsCalling(
            systemPrompt: systemPrompt,
            apiUrl: currentApi.url,
            apiKey: currentApi.apiKey,
            modelName: currentApi.modelName,
            messages: await messages.toOpenAiMessages(),
            prompt: prompt,
            temperature: temperature,
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

    if (json is List) {
      for (final dynamic entry in json) {
        if (entry is Map<String, dynamic> &&
            functionsNames.contains(entry['function'])) {
          final FunctionInfo functionInfo = functions.firstWhere(
            (FunctionInfo e) => e.name == entry['function'],
          );
          functionsCalled.add(
            functionInfo.copyWith(
              parametersCalled: entry['parameters'] as Map<String, dynamic>,
            ),
          );
        }
      }
    } else if (json is Map<String, dynamic>) {
      if (json['function'] != null &&
          json['function'] != 'null' &&
          functionsNames.contains(json['function'])) {
        final FunctionInfo functionInfo = functions.firstWhere(
          (FunctionInfo e) => e.name == json['function'],
        );
        functionsCalled.add(
          functionInfo.copyWith(
            parametersCalled: json['parameters'] as Map<String, dynamic>,
          ),
        );
      }
    }

    return functionsCalled;
  }
}
