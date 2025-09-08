import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/llm_api.dart';
import '../models/message.dart';
import '../models/simple_conversation_memory.dart';
import '../models/simple_user_memory.dart';
import '../repositories/llm_repository.dart';
import 'simple_memory_service.dart';

/// Simplified memory extractor that replaces the complex 3-LLM-call system
/// with a single simple extraction focused on essential facts and basic topics
class SimpleMemoryExtractor {
  /// Extract memories from a conversation using a single, simple LLM analysis
  static Future<void> extractMemoriesFromConversation({
    required List<Message> messages,
    String conversationId = 'default',
    String userContext = 'default_user',
    LlmApi? api,
  }) async {
    if (!await SimpleMemoryService.isMemoryEnabled()) {
      return;
    }

    try {
      // Single LLM call to extract both facts and topics
      final Map<String, dynamic> extractedData = await _extractSimpleMemories(
        messages: messages,
        api: api,
      );

      // Store user facts if any were extracted
      if (extractedData.containsKey('facts') && 
          extractedData['facts'] is Map &&
          (extractedData['facts'] as Map).isNotEmpty) {
        final Map<String, String> facts = Map<String, String>.from(
          extractedData['facts'] as Map
        );
        await SimpleMemoryService.updateUserFacts(
          userContext: userContext,
          newFacts: facts,
        );
      }

      // Store conversation topics if any were extracted
      if (extractedData.containsKey('topics') && 
          extractedData['topics'] is List &&
          (extractedData['topics'] as List).isNotEmpty) {
        final List<String> topics = List<String>.from(
          extractedData['topics'] as List
        );
        await SimpleMemoryService.updateConversationTopics(
          conversationId: conversationId,
          topics: topics,
        );
      }

      if (kDebugMode) {
        debugPrint('SimpleMemoryExtractor: Successfully extracted memories from conversation: $conversationId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SimpleMemoryExtractor: Error extracting memories: $e');
      }
    }
  }

  /// Single LLM call to extract both facts and topics
  static Future<Map<String, dynamic>> _extractSimpleMemories({
    required List<Message> messages,
    LlmApi? api,
  }) async {
    final String extractionPrompt = _buildSimpleExtractionPrompt(messages);

    final List<Message> extractionMessages = <Message>[
      Message(
        role: MessageRole.user,
        body: extractionPrompt,
      ),
    ];

    final String systemPrompt = _getSimpleExtractionSystemPrompt();

    final String response = await LLMRepository.promptModel(
      api: api,
      messages: extractionMessages,
      systemPrompt: systemPrompt,
      returnJson: true,
      useSmallApi: true,
      useMemory: false, // Don't use memory when extracting memory!
    );

    return _parseSimpleExtractionResponse(response);
  }

  /// Build a simple extraction prompt focused on essential facts and topics
  static String _buildSimpleExtractionPrompt(List<Message> messages) {
    final String conversationText = messages
        .map((Message msg) => '${msg.role.name.toUpperCase()}: ${msg.body}')
        .join('\n');

    return '''
Analyze this conversation and extract only essential information:

CONVERSATION:
$conversationText

Extract:
1. Basic facts about the user (name, preferences, important personal info)
2. Main topics discussed

Keep it simple - only extract clear, useful facts and obvious topics.
''';
  }

  /// Simple system prompt for extraction
  static String _getSimpleExtractionSystemPrompt() {
    return '''
You are a simple memory extractor. Extract only essential facts and basic topics from conversations.

Return JSON in this format:
{
  "facts": {
    "name": "John",
    "food_likes": "pizza",
    "location": "Paris"
  },
  "topics": ["greeting", "food", "weather"]
}

Rules:
1. Only extract CLEAR, EXPLICIT facts about the user
2. Keep topics simple and general (1-2 words each)
3. Don't analyze tone, mood, or complex patterns
4. If nothing clear to extract, return empty objects: {"facts": {}, "topics": []}

Examples:
- "Hello my name is John :)" → {"facts": {"name": "John"}, "topics": ["greeting"]}
- "I love pizza but hate broccoli" → {"facts": {"food_likes": "pizza", "food_dislikes": "broccoli"}, "topics": ["food"]}
- "How's the weather?" → {"facts": {}, "topics": ["weather"]}
''';
  }

  /// Parse the simple extraction response
  static Map<String, dynamic> _parseSimpleExtractionResponse(String response) {
    try {
      final Map<String, dynamic> data = jsonDecode(response) as Map<String, dynamic>;
      final Map<String, dynamic> result = <String, dynamic>{};

      // Extract facts (ensure they're strings)
      if (data.containsKey('facts') && data['facts'] is Map) {
        final Map<String, dynamic> rawFacts = data['facts'] as Map<String, dynamic>;
        final Map<String, String> facts = <String, String>{};
        
        rawFacts.forEach((key, value) {
          if (key is String && value != null) {
            facts[key] = value.toString();
          }
        });
        
        if (facts.isNotEmpty) {
          result['facts'] = facts;
        }
      }

      // Extract topics (ensure they're strings)
      if (data.containsKey('topics') && data['topics'] is List) {
        final List<dynamic> rawTopics = data['topics'] as List<dynamic>;
        final List<String> topics = rawTopics
            .where((topic) => topic != null)
            .map((topic) => topic.toString().toLowerCase().trim())
            .where((topic) => topic.isNotEmpty)
            .toList();
        
        if (topics.isNotEmpty) {
          result['topics'] = topics;
        }
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SimpleMemoryExtractor: Error parsing extraction response: $e');
        debugPrint('SimpleMemoryExtractor: Raw response: $response');
      }
      return <String, dynamic>{};
    }
  }
}