import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/llm_api.dart';

class CacheService {
  static const String _savedList = 'llms_apis_saved';
  static const String _currentApi = 'current_api';
  static const String _currentSmallApi = 'current_small_api';

  static Future<List<LlmApi>> getSavedLlmApis() async {
    final List<String> savedList = await _getSavedList();
    final List<LlmApi> apis = <LlmApi>[];
    for (final String s in savedList) {
      apis.add(LlmApi.fromMap(jsonDecode(s) as Map<String, dynamic>));
    }
    return apis;
  }

  static Future<List<String>> _getSavedList() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String>? savedLlmApisJson = prefs.getStringList(_savedList);
    if (savedLlmApisJson == null) return <String>[];
    return savedLlmApisJson;
  }

  static Future<void> updateSavedList(LlmApi llmApis) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> list = await _getSavedList();
    list.add(jsonEncode(llmApis.toMap()));
    await prefs.setStringList(_savedList, list);
  }

  static Future<void> updateExistingEntry(LlmApi llmApis) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<LlmApi> list = await getSavedLlmApis();
    final int index = list.indexWhere((LlmApi x) => x.id == llmApis.id);
    list[index] = llmApis;
    final List<String> strList = <String>[];
    for (final LlmApi api in list) {
      strList.add(jsonEncode(api.toMap()));
    }
    await prefs.setStringList(_savedList, strList);
  }

  static Future<void> deleteEntryList(LlmApi llmApis) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final List<String> list = await _getSavedList();
    list.removeWhere((String x) => x == jsonEncode(llmApis.toMap()));
    await prefs.setStringList(_savedList, list);
  }

  static Future<void> setCurrentApi(LlmApi llmApis) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentApi, llmApis.id);
  }

  static Future<LlmApi?> getCurrentApi() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? currentApi = prefs.getString(_currentApi);
    if (currentApi == null) return null;
    final List<LlmApi> apis = await getSavedLlmApis();
    try {
      return apis.firstWhere((LlmApi x) => x.id == currentApi);
    } catch (e) {
      return null;
    }
  }

  static Future<void> setLastRequestTime(String modelName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_request_time_$modelName', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<DateTime?> getLastRequestTime(String modelName) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? lastRequestTime = prefs.getInt('last_request_time_$modelName');
    if (lastRequestTime == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(lastRequestTime);
  }

  static Future<void> setCurrentSmallApi(LlmApi llmApis) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentSmallApi, llmApis.id);
  }

  static Future<LlmApi?> getCurrentSmallApi() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? currentSmallApi = prefs.getString(_currentSmallApi);
    if (currentSmallApi == null) return null;
    final List<LlmApi> apis = await getSavedLlmApis();
    try {
      return apis.firstWhere((LlmApi x) => x.id == currentSmallApi);
    } catch (e) {
      return null;
    }
  }

}
