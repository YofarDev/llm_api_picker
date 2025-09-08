import 'package:flutter/foundation.dart';

import '../models/simple_conversation_memory.dart';
import '../models/simple_user_memory.dart';
import 'memory_database.dart';

/// Simplified memory service that replaces the complex MemoryService
/// Focuses only on essential user facts and basic conversation topics
class SimpleMemoryService {
  static const String _memoryEnabledKey = 'memory_enabled';
  static const String _defaultUserContext = 'default_user';

  /// Check if memory is enabled
  static Future<bool> isMemoryEnabled() async {
    final String? setting = await MemoryDatabase.getMemorySetting(_memoryEnabledKey);
    if (kDebugMode) {
      debugPrint('SimpleMemoryService: isMemoryEnabled() - Retrieved setting: $setting');
    }
    return setting == 'true';
  }

  /// Enable or disable memory
  static Future<void> setMemoryEnabled(bool enabled) async {
    if (kDebugMode) {
      debugPrint('SimpleMemoryService: setMemoryEnabled() - Setting to: $enabled');
    }
    await MemoryDatabase.setMemorySetting(_memoryEnabledKey, enabled.toString());
  }

  /// Initialize memory service
  static Future<void> initialize() async {
    try {
      // Initialize database
      await MemoryDatabase.database;

      // Ensure simple memory tables exist (for existing databases)
      await MemoryDatabase.ensureSimpleMemoryTables();

      // Set default memory enabled state if not set
      final String? memoryEnabled = await MemoryDatabase.getMemorySetting(_memoryEnabledKey);
      if (memoryEnabled == null) {
        if (kDebugMode) {
          debugPrint('SimpleMemoryService: No memory enabled setting found, defaulting to false.');
        }
        await setMemoryEnabled(false); // Default to disabled
      } else {
        if (kDebugMode) {
          debugPrint('SimpleMemoryService: Memory enabled setting found: $memoryEnabled');
        }
      }

      if (kDebugMode) {
        debugPrint('SimpleMemoryService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SimpleMemoryService: Error initializing: $e');
      }
    }
  }

  // User Memory Operations

  /// Get or create user memory for a user context
  static Future<SimpleUserMemory> getOrCreateUserMemory({
    String userContext = _defaultUserContext,
  }) async {
    if (!await isMemoryEnabled()) {
      throw Exception('Memory is disabled');
    }

    // Try to get existing user memory from database
    // For now, we'll use the semantic memory table but with simplified data
    try {
      final Map<String, dynamic>? existingData = await MemoryDatabase.getSimpleUserMemory(userContext);
      
      if (existingData != null) {
        return SimpleUserMemory.fromMap(existingData);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SimpleMemoryService: Error getting existing user memory: $e');
      }
    }

    // Create new user memory
    final SimpleUserMemory memory = SimpleUserMemory.create(userContext: userContext);
    await MemoryDatabase.insertSimpleUserMemory(memory);
    return memory;
  }

  /// Update user facts
  static Future<SimpleUserMemory> updateUserFacts({
    String userContext = _defaultUserContext,
    required Map<String, String> newFacts,
  }) async {
    if (!await isMemoryEnabled()) {
      throw Exception('Memory is disabled');
    }

    final SimpleUserMemory currentMemory = await getOrCreateUserMemory(userContext: userContext);
    final SimpleUserMemory updatedMemory = currentMemory.updateFacts(newFacts);

    await MemoryDatabase.insertSimpleUserMemory(updatedMemory);
    
    if (kDebugMode) {
      debugPrint('SimpleMemoryService: Updated user facts for $userContext: $newFacts');
    }
    
    return updatedMemory;
  }

  /// Get user facts
  static Future<Map<String, String>> getUserFacts({
    String userContext = _defaultUserContext,
  }) async {
    if (!await isMemoryEnabled()) {
      return <String, String>{};
    }

    try {
      final SimpleUserMemory memory = await getOrCreateUserMemory(userContext: userContext);
      return memory.facts;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SimpleMemoryService: Error getting user facts: $e');
      }
      return <String, String>{};
    }
  }

  // Conversation Memory Operations

  /// Get or create conversation memory
  static Future<SimpleConversationMemory> getOrCreateConversationMemory({
    required String conversationId,
  }) async {
    if (!await isMemoryEnabled()) {
      throw Exception('Memory is disabled');
    }

    // Try to get existing conversation memory from database
    try {
      final Map<String, dynamic>? existingData = await MemoryDatabase.getSimpleConversationMemory(conversationId);
      
      if (existingData != null) {
        return SimpleConversationMemory.fromMap(existingData);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SimpleMemoryService: Error getting existing conversation memory: $e');
      }
    }

    // Create new conversation memory
    final SimpleConversationMemory memory = SimpleConversationMemory.create(conversationId: conversationId);
    await MemoryDatabase.insertSimpleConversationMemory(memory);
    return memory;
  }

  /// Update conversation topics
  static Future<SimpleConversationMemory> updateConversationTopics({
    required String conversationId,
    required List<String> topics,
  }) async {
    if (!await isMemoryEnabled()) {
      throw Exception('Memory is disabled');
    }

    final SimpleConversationMemory currentMemory = await getOrCreateConversationMemory(conversationId: conversationId);
    final SimpleConversationMemory updatedMemory = currentMemory.addTopics(topics);

    await MemoryDatabase.insertSimpleConversationMemory(updatedMemory);
    
    if (kDebugMode) {
      debugPrint('SimpleMemoryService: Updated conversation topics for $conversationId: $topics');
    }
    
    return updatedMemory;
  }

  /// Get recent conversation topics (last 5 conversations)
  static Future<List<String>> getRecentTopics({int limit = 5}) async {
    if (!await isMemoryEnabled()) {
      return <String>[];
    }

    try {
      final List<SimpleConversationMemory> recentConversations = 
          await MemoryDatabase.getRecentSimpleConversationMemories(limit: limit);
      
      final Set<String> allTopics = <String>{};
      for (final SimpleConversationMemory conversation in recentConversations) {
        allTopics.addAll(conversation.topics);
      }
      
      return allTopics.toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SimpleMemoryService: Error getting recent topics: $e');
      }
      return <String>[];
    }
  }

  // Memory Context Generation

  /// Get simple memory context for enhancing LLM prompts
  static Future<String> getMemoryContext({
    String userContext = _defaultUserContext,
    String? conversationId,
  }) async {
    if (!await isMemoryEnabled()) {
      return '';
    }

    try {
      final List<String> contextParts = <String>[];

      // Get user facts
      final Map<String, String> userFacts = await getUserFacts(userContext: userContext);
      if (userFacts.isNotEmpty) {
        final String factsString = userFacts.entries
            .map((entry) => '${entry.key}: ${entry.value}')
            .join(', ');
        contextParts.add('User: $factsString');
      }

      // Get recent topics
      final List<String> recentTopics = await getRecentTopics();
      if (recentTopics.isNotEmpty) {
        contextParts.add('Previous topics: ${recentTopics.join(', ')}');
      }

      return contextParts.join('\n');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SimpleMemoryService: Error getting memory context: $e');
      }
      return '';
    }
  }

  // Cleanup Operations

  /// Clean up old conversation memories (older than specified days)
  static Future<void> cleanupOldConversations({int olderThanDays = 90}) async {
    if (!await isMemoryEnabled()) {
      return;
    }

    try {
      await MemoryDatabase.deleteOldSimpleConversationMemories(olderThanDays: olderThanDays);
      
      if (kDebugMode) {
        debugPrint('SimpleMemoryService: Cleaned up conversations older than $olderThanDays days');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SimpleMemoryService: Error cleaning up old conversations: $e');
      }
    }
  }
}