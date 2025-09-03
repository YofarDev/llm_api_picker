import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/llm_api.dart';
import '../models/message.dart';
import '../repositories/llm_repository.dart';
import 'memory_service.dart';

/// Service for extracting and consolidating memories from conversations using LLM analysis
class MemoryExtractor {
  /// Extract memories from a conversation using LLM analysis
  static Future<void> extractMemoriesFromConversation({
    required List<Message> messages,
    String conversationId = 'default',
    String userContext = 'default_user',
    LlmApi? api,
  }) async {
    if (!await MemoryService.isMemoryEnabled()) {
      return;
    }

    try {
      // Extract semantic memories (facts, preferences, knowledge)
      await _extractSemanticMemories(
        messages: messages,
        userContext: userContext,
        api: api,
      );

      // Extract episodic memories (conversation summaries, experiences)
      await _extractEpisodicMemories(
        messages: messages,
        conversationId: conversationId,
        api: api,
      );

      // Extract procedural memories (successful patterns, behaviors)
      await _extractProceduralMemories(
        messages: messages,
        api: api,
      );

      if (kDebugMode) {
        print(
            'Successfully extracted memories from conversation: $conversationId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting memories from conversation: $e');
      }
    }
  }

  /// Extract semantic memories (facts, preferences, knowledge) from conversation
  static Future<void> _extractSemanticMemories({
    required List<Message> messages,
    required String userContext,
    LlmApi? api,
  }) async {
    try {
      final String extractionPrompt = _buildSemanticExtractionPrompt(messages);

      final List<Message> extractionMessages = <Message>[
        Message(
          role: MessageRole.user,
          body: extractionPrompt,
        ),
      ];

      final String systemPrompt = await _getSemanticExtractionSystemPrompt();

      final String response = await LLMRepository.promptModel(
        api: api,
        messages: extractionMessages,
        systemPrompt: systemPrompt,
        returnJson: true,
        useSmallApi: true,
      );

      final Map<String, dynamic> extractedData =
          _parseSemanticExtractionResponse(response);

      if (extractedData.isNotEmpty) {
        await MemoryService.updateSemanticMemory(
          userContext: userContext,
          newData: extractedData,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting semantic memories: $e');
      }
    }
  }

  /// Extract episodic memories (conversation summaries) from conversation
  static Future<void> _extractEpisodicMemories({
    required List<Message> messages,
    required String conversationId,
    LlmApi? api,
  }) async {
    try {
      final String extractionPrompt = _buildEpisodicExtractionPrompt(messages);

      final List<Message> extractionMessages = <Message>[
        Message(
          role: MessageRole.user,
          body: extractionPrompt,
        ),
      ];

      final String systemPrompt = await _getEpisodicExtractionSystemPrompt();

      final String response = await LLMRepository.promptModel(
        api: api,
        messages: extractionMessages,
        systemPrompt: systemPrompt,
        returnJson: true,
        useSmallApi: true,
      );

      final List<Map<String, dynamic>> extractedMemories =
          _parseEpisodicExtractionResponse(response);

      for (final Map<String, dynamic> memoryData in extractedMemories) {
        await MemoryService.storeConversationMemory(
          conversationId: conversationId,
          summary: memoryData['summary'] as String,
          context: memoryData['context'] as String,
          relevanceScore:
              (memoryData['relevance_score'] as num?)?.toDouble() ?? 1.0,
          tags: (memoryData['tags'] as List<dynamic>?)?.cast<String>() ??
              <String>[],
          metadata: memoryData['metadata'] as Map<String, dynamic>?,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting episodic memories: $e');
      }
    }
  }

  /// Extract procedural memories (successful patterns) from conversation
  static Future<void> _extractProceduralMemories({
    required List<Message> messages,
    LlmApi? api,
  }) async {
    try {
      final String extractionPrompt =
          _buildProceduralExtractionPrompt(messages);

      final List<Message> extractionMessages = <Message>[
        Message(
          role: MessageRole.user,
          body: extractionPrompt,
        ),
      ];

      final String systemPrompt = await _getProceduralExtractionSystemPrompt();

      final String response = await LLMRepository.promptModel(
        api: api,
        messages: extractionMessages,
        systemPrompt: systemPrompt,
        returnJson: true,
        useSmallApi: true,
      );

      final List<Map<String, dynamic>> extractedPatterns =
          _parseProceduralExtractionResponse(response);

      for (final Map<String, dynamic> patternData in extractedPatterns) {
        await MemoryService.storeProceduralPattern(
          patternType: patternData['pattern_type'] as String,
          ruleData: patternData['rule_data'] as Map<String, dynamic>,
          successRate: (patternData['success_rate'] as num?)?.toDouble() ?? 1.0,
          description: patternData['description'] as String?,
          conditions: patternData['conditions'] as Map<String, dynamic>?,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error extracting procedural memories: $e');
      }
    }
  }

  // Prompt Building Methods

  static String _buildSemanticExtractionPrompt(List<Message> messages) {
    final String conversationText = messages
        .map((Message msg) => '${msg.role.name.toUpperCase()}: ${msg.body}')
        .join('\n');

    return '''
Analyze the following conversation and extract semantic information (facts, preferences, knowledge) about the user:

CONVERSATION:
$conversationText

Extract any user preferences, facts about the user, knowledge they've shared, or personal information that would be useful for future conversations. Focus on information that would help personalize future interactions.
''';
  }

  static String _buildEpisodicExtractionPrompt(List<Message> messages) {
    final String conversationText = messages
        .map((Message msg) => '${msg.role.name.toUpperCase()}: ${msg.body}')
        .join('\n');

    return '''
Analyze the following conversation and create a summary that captures the key experiences, outcomes, and context:

CONVERSATION:
$conversationText

Create a concise summary that captures:
1. What the conversation was about
2. Key outcomes or results
3. Important context that might be relevant for future conversations
4. Any successful approaches or solutions that were found
''';
  }

  static String _buildProceduralExtractionPrompt(List<Message> messages) {
    final String conversationText = messages
        .map((Message msg) => '${msg.role.name.toUpperCase()}: ${msg.body}')
        .join('\n');

    return '''
Analyze the following conversation and identify successful behavioral patterns, response styles, or approaches that worked well:

CONVERSATION:
$conversationText

Look for:
1. Response styles that the user responded well to
2. Successful problem-solving approaches
3. Communication patterns that led to positive outcomes
4. Techniques or methods that were effective
''';
  }

  // System Prompts

  static Future<String> _getSemanticExtractionSystemPrompt() async {
    try {
      return await rootBundle.loadString(
        'packages/llm_api_picker/lib/assets/memory_semantic_extraction_prompt.txt',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error loading semantic extraction prompt: $e');
      }
      // Fallback to hardcoded prompt
      return '''
You are a memory extraction specialist focused on semantic information. Your job is to analyze conversations and extract factual information, user preferences, and knowledge that can be stored for future reference.

Return your response as JSON in this format:
{
  "preferences": {
    "key": "value"
  },
  "facts": {
    "key": "value"
  },
  "knowledge": {
    "key": "value"
  }
}

Only extract information that is:
1. Explicitly stated or clearly implied
2. Factual and verifiable
3. Useful for personalizing future interactions
4. Respectful of privacy

If no semantic information can be extracted, return an empty JSON object: {}
''';
    }
  }

  static Future<String> _getEpisodicExtractionSystemPrompt() async {
    try {
      return await rootBundle.loadString(
        'packages/llm_api_picker/lib/assets/memory_episodic_extraction_prompt.txt',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error loading episodic extraction prompt: $e');
      }
      // Fallback to hardcoded prompt
      return '''
You are a memory extraction specialist focused on episodic information. Your job is to create meaningful summaries of conversations that capture experiences, outcomes, and context.

Return your response as JSON in this format:
{
  "memories": [
    {
      "summary": "Brief summary of the key experience or outcome",
      "context": "Additional context that might be relevant later",
      "relevance_score": 0.8,
      "tags": ["tag1", "tag2"],
      "metadata": {
        "topic": "main topic",
        "outcome": "positive/negative/neutral"
      }
    }
  ]
}

Create summaries that:
1. Capture the essence of what happened
2. Include relevant context for future reference
3. Assign appropriate relevance scores (0.0 to 1.0)
4. Use descriptive tags for categorization
5. Are concise but informative

If the conversation doesn't contain memorable experiences, return: {"memories": []}
''';
    }
  }

  static Future<String> _getProceduralExtractionSystemPrompt() async {
    try {
      return await rootBundle.loadString(
        'packages/llm_api_picker/lib/assets/memory_procedural_extraction_prompt.txt',
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error loading procedural extraction prompt: $e');
      }
      // Fallback to hardcoded prompt
      return '''
You are a memory extraction specialist focused on procedural information. Your job is to identify successful behavioral patterns, response styles, and approaches that can be reused in future interactions.

Return your response as JSON in this format:
{
  "patterns": [
    {
      "pattern_type": "response_style|problem_solving|communication|technique",
      "rule_data": {
        "approach": "description of the approach",
        "context": "when to use this pattern"
      },
      "success_rate": 0.9,
      "description": "Brief description of why this pattern was successful",
      "conditions": {
        "topic": "relevant topic",
        "user_mood": "positive|neutral|negative"
      }
    }
  ]
}

Look for patterns that:
1. Led to positive outcomes
2. Solved problems effectively
3. Improved communication
4. Can be generalized for future use
5. Have clear success indicators

If no successful patterns can be identified, return: {"patterns": []}
''';
    }
  }

  // Response Parsing Methods

  static Map<String, dynamic> _parseSemanticExtractionResponse(
      String response) {
    try {
      final Map<String, dynamic> data =
          jsonDecode(response) as Map<String, dynamic>;
      final Map<String, dynamic> result = <String, dynamic>{};

      // Extract preferences
      if (data.containsKey('preferences') && data['preferences'] is Map) {
        result['preferences'] = data['preferences'];
      }

      // Extract facts
      if (data.containsKey('facts') && data['facts'] is Map) {
        result['facts'] = data['facts'];
      }

      // Extract knowledge
      if (data.containsKey('knowledge') && data['knowledge'] is Map) {
        result['knowledge'] = data['knowledge'];
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing semantic extraction response: $e');
      }
      return <String, dynamic>{};
    }
  }

  static List<Map<String, dynamic>> _parseEpisodicExtractionResponse(
      String response) {
    try {
      final Map<String, dynamic> data =
          jsonDecode(response) as Map<String, dynamic>;
      if (data.containsKey('memories') && data['memories'] is List) {
        return (data['memories'] as List<dynamic>).cast<Map<String, dynamic>>();
      }
      return <Map<String, dynamic>>[];
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing episodic extraction response: $e');
      }
      return <Map<String, dynamic>>[];
    }
  }

  static List<Map<String, dynamic>> _parseProceduralExtractionResponse(
      String response) {
    try {
      final Map<String, dynamic> data =
          jsonDecode(response) as Map<String, dynamic>;
      if (data.containsKey('patterns') && data['patterns'] is List) {
        return (data['patterns'] as List<dynamic>).cast<Map<String, dynamic>>();
      }
      return <Map<String, dynamic>>[];
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing procedural extraction response: $e');
      }
      return <Map<String, dynamic>>[];
    }
  }

  /// Consolidate similar memories to avoid duplication
  static Future<void> consolidateMemories() async {
    if (!await MemoryService.isMemoryEnabled()) {
      return;
    }

    try {
      await _consolidateEpisodicMemories();
      await _consolidateProceduralMemories();

      if (kDebugMode) {
        print('Memory consolidation completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during memory consolidation: $e');
      }
    }
  }

  /// Consolidate similar episodic memories
  static Future<void> _consolidateEpisodicMemories() async {
    // This would implement logic to find similar episodic memories
    // and merge them to avoid duplication
    // For now, this is a placeholder for future implementation
  }

  /// Consolidate similar procedural memories
  static Future<void> _consolidateProceduralMemories() async {
    // This would implement logic to find similar procedural patterns
    // and merge or update them based on success rates
    // For now, this is a placeholder for future implementation
  }
}
