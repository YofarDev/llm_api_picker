import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/episodic_memory.dart';
import '../models/memory_base.dart';
import '../models/procedural_memory.dart';
import '../models/semantic_memory.dart';
import 'memory_database.dart';

/// Main service class for managing all memory operations
/// Implements the LangMem pattern: Accept conversation -> Analyze with LLM -> Update memory
class MemoryService {
  static const String _memoryEnabledKey = 'memory_enabled';
  static const String _defaultUserContext = 'default_user';
  static const Uuid _uuid = Uuid();

  /// Check if memory is enabled
  static Future<bool> isMemoryEnabled() async {
    final String? setting =
        await MemoryDatabase.getMemorySetting(_memoryEnabledKey);
    return setting == 'true';
  }

  /// Enable or disable memory
  static Future<void> setMemoryEnabled(bool enabled) async {
    await MemoryDatabase.setMemorySetting(
        _memoryEnabledKey, enabled.toString());
  }

  /// Initialize memory service (call this when the app starts)
  static Future<void> initialize() async {
    try {
      // Initialize database
      await MemoryDatabase.database;

      // Set default memory enabled state if not set
      final String? memoryEnabled =
          await MemoryDatabase.getMemorySetting(_memoryEnabledKey);
      if (memoryEnabled == null) {
        await setMemoryEnabled(false); // Default to disabled
      }

      if (kDebugMode) {
        print('MemoryService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing MemoryService: $e');
      }
    }
  }

  // Semantic Memory Operations

  /// Get or create semantic memory for a user context
  static Future<SemanticMemory> getOrCreateSemanticMemory({
    String userContext = _defaultUserContext,
  }) async {
    if (!await isMemoryEnabled()) {
      throw Exception('Memory is disabled');
    }

    SemanticMemory? memory =
        await MemoryDatabase.getSemanticMemory(userContext);

    if (memory == null) {
      // Create new semantic memory with default profile
      memory = SemanticMemory.create(
        id: _uuid.v4(),
        userContext: userContext,
        profileData: <String, dynamic>{
          'preferences': <String, dynamic>{},
          'facts': <String, dynamic>{},
          'knowledge': <String, dynamic>{},
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      await MemoryDatabase.insertSemanticMemory(memory);
    }

    return memory;
  }

  /// Update semantic memory with new information
  static Future<SemanticMemory> updateSemanticMemory({
    String userContext = _defaultUserContext,
    required Map<String, dynamic> newData,
  }) async {
    if (!await isMemoryEnabled()) {
      throw Exception('Memory is disabled');
    }

    final SemanticMemory currentMemory =
        await getOrCreateSemanticMemory(userContext: userContext);
    final SemanticMemory updatedMemory = currentMemory.update(newData);

    await MemoryDatabase.insertSemanticMemory(updatedMemory);
    return updatedMemory;
  }

  /// Get semantic memory profile data
  static Future<Map<String, dynamic>> getSemanticProfile({
    String userContext = _defaultUserContext,
  }) async {
    if (!await isMemoryEnabled()) {
      return <String, dynamic>{};
    }

    final SemanticMemory? memory =
        await MemoryDatabase.getSemanticMemory(userContext);
    return memory?.profileData ?? <String, dynamic>{};
  }

  // Episodic Memory Operations

  /// Store a conversation as episodic memory
  static Future<EpisodicMemory> storeConversationMemory({
    required String conversationId,
    required String summary,
    required String context,
    double relevanceScore = 1.0,
    List<String> tags = const <String>[],
    Map<String, dynamic>? metadata,
  }) async {
    if (!await isMemoryEnabled()) {
      throw Exception('Memory is disabled');
    }

    final EpisodicMemory memory = EpisodicMemory.create(
      id: _uuid.v4(),
      conversationId: conversationId,
      summary: summary,
      context: context,
      relevanceScore: relevanceScore,
      tags: tags,
      metadata: metadata,
    );

    await MemoryDatabase.insertEpisodicMemory(memory);
    return memory;
  }

  /// Retrieve relevant episodic memories
  static Future<List<EpisodicMemory>> getRelevantEpisodicMemories({
    String? conversationId,
    List<String>? tags,
    int limit = 5,
  }) async {
    if (!await isMemoryEnabled()) {
      return <EpisodicMemory>[];
    }

    if (conversationId != null) {
      return await MemoryDatabase.getEpisodicMemoriesByConversation(
          conversationId);
    } else if (tags != null && tags.isNotEmpty) {
      return await MemoryDatabase.searchEpisodicMemoriesByTags(tags);
    } else {
      return await MemoryDatabase.getTopEpisodicMemories(limit: limit);
    }
  }

  /// Update episodic memory relevance score
  static Future<void> updateEpisodicMemoryRelevance(
      String memoryId, double newScore) async {
    if (!await isMemoryEnabled()) return;

    // This would require getting the memory first, updating it, then saving
    // For now, we'll implement this as a direct database update
    // In a full implementation, you'd want to load, update, and save the object
  }

  // Procedural Memory Operations

  /// Store a behavioral pattern as procedural memory
  static Future<ProceduralMemory> storeProceduralPattern({
    required String patternType,
    required Map<String, dynamic> ruleData,
    double successRate = 1.0,
    String? description,
    Map<String, dynamic>? conditions,
  }) async {
    if (!await isMemoryEnabled()) {
      throw Exception('Memory is disabled');
    }

    final ProceduralMemory memory = ProceduralMemory.create(
      id: _uuid.v4(),
      patternType: patternType,
      ruleData: ruleData,
      successRate: successRate,
      description: description,
      conditions: conditions,
    );

    await MemoryDatabase.insertProceduralMemory(memory);
    return memory;
  }

  /// Get procedural patterns by type
  static Future<List<ProceduralMemory>> getProceduralPatterns({
    String? patternType,
    int limit = 10,
  }) async {
    if (!await isMemoryEnabled()) {
      return <ProceduralMemory>[];
    }

    if (patternType != null) {
      return await MemoryDatabase.getProceduralMemoriesByType(patternType);
    } else {
      return await MemoryDatabase.getTopProceduralMemories(limit: limit);
    }
  }

  /// Record success or failure of a procedural pattern
  static Future<void> recordProceduralPatternUsage(
      String memoryId, bool success) async {
    if (!await isMemoryEnabled()) return;

    // This would require getting the memory, updating it, then saving
    // Implementation would load the procedural memory, call recordSuccess() or recordFailure(),
    // then save it back to the database
  }

  // Memory Retrieval and Context Enhancement

  /// Get memory context for enhancing LLM prompts
  static Future<String> getMemoryContext({
    String userContext = _defaultUserContext,
    String? conversationId,
    List<String>? tags,
    int maxEpisodicMemories = 3,
    int maxProceduralPatterns = 2,
  }) async {
    if (!await isMemoryEnabled()) {
      return '';
    }

    final List<String> contextParts = <String>[];

    try {
      // Get semantic memory (user profile)
      final Map<String, dynamic> semanticProfile =
          await getSemanticProfile(userContext: userContext);
      if (semanticProfile.isNotEmpty) {
        contextParts
            .add('User Profile: ${_formatProfileForContext(semanticProfile)}');
      }

      // Get relevant episodic memories
      final List<EpisodicMemory> episodicMemories =
          await getRelevantEpisodicMemories(
        conversationId: conversationId,
        tags: tags,
        limit: maxEpisodicMemories,
      );
      if (episodicMemories.isNotEmpty) {
        final String episodicContext = episodicMemories
            .map(
                (EpisodicMemory memory) => 'Past Experience: ${memory.summary}')
            .join('\n');
        contextParts.add('Relevant Past Experiences:\n$episodicContext');
      }

      // Get relevant procedural patterns
      final List<ProceduralMemory> proceduralPatterns =
          await getProceduralPatterns(limit: maxProceduralPatterns);
      if (proceduralPatterns.isNotEmpty) {
        final String proceduralContext = proceduralPatterns
            .map((ProceduralMemory pattern) =>
                'Successful Pattern (${pattern.patternType}): ${pattern.description ?? 'Success rate: ${(pattern.successRate * 100).toStringAsFixed(1)}%'}')
            .join('\n');
        contextParts.add('Behavioral Patterns:\n$proceduralContext');
      }

      return contextParts.join('\n\n');
    } catch (e) {
      if (kDebugMode) {
        print('Error getting memory context: $e');
      }
      return '';
    }
  }

  /// Format semantic profile for context injection
  static String _formatProfileForContext(Map<String, dynamic> profile) {
    final List<String> parts = <String>[];

    if (profile.containsKey('preferences') && profile['preferences'] is Map) {
      final Map<String, dynamic> prefs =
          profile['preferences'] as Map<String, dynamic>;
      if (prefs.isNotEmpty) {
        parts.add(
            'Preferences: ${prefs.entries.map((MapEntry<String, dynamic> e) => '${e.key}: ${e.value}').join(', ')}');
      }
    }

    if (profile.containsKey('facts') && profile['facts'] is Map) {
      final Map<String, dynamic> facts =
          profile['facts'] as Map<String, dynamic>;
      if (facts.isNotEmpty) {
        parts.add(
            'Known Facts: ${facts.entries.map((MapEntry<String, dynamic> e) => '${e.key}: ${e.value}').join(', ')}');
      }
    }

    return parts.join('; ');
  }

  // Memory Management and Statistics

  /// Get memory statistics
  static Future<MemoryStats> getMemoryStatistics() async {
    if (!await isMemoryEnabled()) {
      return MemoryStats.empty();
    }

    try {
      final Map<String, int> stats = await MemoryDatabase.getMemoryStatistics();

      return MemoryStats(
        totalMemories: stats['total'] ?? 0,
        semanticCount: stats['semantic'] ?? 0,
        episodicCount: stats['episodic'] ?? 0,
        proceduralCount: stats['procedural'] ?? 0,
        lastUpdated: DateTime.now(),
        totalRetrievals: 0, // Would need to track this separately
        averageRelevanceScore: 0.0, // Would need to calculate this
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error getting memory statistics: $e');
      }
      return MemoryStats.empty();
    }
  }

  /// Clear all memories
  static Future<void> clearAllMemories() async {
    await MemoryDatabase.clearAllMemories();
  }

  /// Clear memories by type
  static Future<void> clearMemoriesByType(MemoryType type) async {
    switch (type) {
      case MemoryType.semantic:
        final List<SemanticMemory> memories =
            await MemoryDatabase.getAllSemanticMemories();
        for (final SemanticMemory memory in memories) {
          await MemoryDatabase.deleteSemanticMemory(memory.id);
        }
      case MemoryType.episodic:
        final List<EpisodicMemory> memories =
            await MemoryDatabase.getAllEpisodicMemories();
        for (final EpisodicMemory memory in memories) {
          await MemoryDatabase.deleteEpisodicMemory(memory.id);
        }
      case MemoryType.procedural:
        final List<ProceduralMemory> memories =
            await MemoryDatabase.getAllProceduralMemories();
        for (final ProceduralMemory memory in memories) {
          await MemoryDatabase.deleteProceduralMemory(memory.id);
        }
    }
  }

  /// Clean up old memories
  static Future<void> cleanupOldMemories({int daysOld = 90}) async {
    if (!await isMemoryEnabled()) return;

    try {
      // Clean up old episodic memories
      final int deletedCount =
          await MemoryDatabase.deleteOldEpisodicMemories(daysOld);

      if (kDebugMode) {
        print('Cleaned up $deletedCount old episodic memories');
      }

      // Vacuum database to reclaim space
      await MemoryDatabase.vacuum();
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up old memories: $e');
      }
    }
  }

  /// Export memories to JSON
  static Future<Map<String, dynamic>> exportMemories() async {
    if (!await isMemoryEnabled()) {
      return <String, dynamic>{};
    }

    try {
      final List<SemanticMemory> semanticMemories =
          await MemoryDatabase.getAllSemanticMemories();
      final List<EpisodicMemory> episodicMemories =
          await MemoryDatabase.getAllEpisodicMemories();
      final List<ProceduralMemory> proceduralMemories =
          await MemoryDatabase.getAllProceduralMemories();
      final Map<String, String> settings =
          await MemoryDatabase.getAllMemorySettings();

      return <String, dynamic>{
        'export_date': DateTime.now().toIso8601String(),
        'semantic_memories':
            semanticMemories.map((SemanticMemory m) => m.toMap()).toList(),
        'episodic_memories':
            episodicMemories.map((EpisodicMemory m) => m.toMap()).toList(),
        'procedural_memories':
            proceduralMemories.map((ProceduralMemory m) => m.toMap()).toList(),
        'settings': settings,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting memories: $e');
      }
      return <String, dynamic>{};
    }
  }

  /// Import memories from JSON
  static Future<bool> importMemories(Map<String, dynamic> data) async {
    if (!await isMemoryEnabled()) {
      return false;
    }

    try {
      // Import semantic memories
      if (data.containsKey('semantic_memories')) {
        final List<dynamic> semanticData =
            data['semantic_memories'] as List<dynamic>;
        for (final dynamic memoryData in semanticData) {
          final SemanticMemory memory =
              SemanticMemory.fromMap(memoryData as Map<String, dynamic>);
          await MemoryDatabase.insertSemanticMemory(memory);
        }
      }

      // Import episodic memories
      if (data.containsKey('episodic_memories')) {
        final List<dynamic> episodicData = data['episodic_memories'] as List<dynamic>;
        for (final dynamic memoryData in episodicData) {
          final EpisodicMemory memory =
              EpisodicMemory.fromMap(memoryData as Map<String, dynamic>);
          await MemoryDatabase.insertEpisodicMemory(memory);
        }
      }

      // Import procedural memories
      if (data.containsKey('procedural_memories')) {
        final List<dynamic> proceduralData =
            data['procedural_memories'] as List<dynamic>;
        for (final dynamic memoryData in proceduralData) {
          final ProceduralMemory memory =
              ProceduralMemory.fromMap(memoryData as Map<String, dynamic>);
          await MemoryDatabase.insertProceduralMemory(memory);
        }
      }

      // Import settings
      if (data.containsKey('settings')) {
        final Map<String, dynamic> settings =
            data['settings'] as Map<String, dynamic>;
        for (final MapEntry<String, dynamic> entry in settings.entries) {
          await MemoryDatabase.setMemorySetting(
              entry.key, entry.value as String);
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error importing memories: $e');
      }
      return false;
    }
  }
}
