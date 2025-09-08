import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/episodic_memory.dart';
import '../models/procedural_memory.dart';
import '../models/semantic_memory.dart';
import '../models/simple_conversation_memory.dart';
import '../models/simple_user_memory.dart';

/// Database helper class for managing the memory SQLite database
class MemoryDatabase {
  static const String _databaseName = 'llm_memory.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _semanticMemoryTable = 'semantic_memory';
  static const String _episodicMemoryTable = 'episodic_memory';
  static const String _proceduralMemoryTable = 'procedural_memory';
  static const String _memorySettingsTable = 'memory_settings';
  
  // Simple memory table names
  static const String _simpleUserMemoryTable = 'simple_user_memory';
  static const String _simpleConversationMemoryTable = 'simple_conversation_memory';

  static Database? _database;

  /// Get the database instance (singleton pattern)
  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  static Future<Database> _initDatabase() async {
    final String documentsDirectory = await getDatabasesPath();
    final String path = join(documentsDirectory, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  static Future<void> _onCreate(Database db, int version) async {
    // Create semantic memory table
    await db.execute('''
      CREATE TABLE $_semanticMemoryTable (
        id TEXT PRIMARY KEY,
        user_context TEXT NOT NULL,
        profile_data TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        version INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create episodic memory table
    await db.execute('''
      CREATE TABLE $_episodicMemoryTable (
        id TEXT PRIMARY KEY,
        conversation_id TEXT NOT NULL,
        summary TEXT NOT NULL,
        context TEXT NOT NULL,
        relevance_score REAL NOT NULL DEFAULT 1.0,
        created_at INTEGER NOT NULL,
        tags TEXT NOT NULL DEFAULT '[]',
        metadata TEXT
      )
    ''');

    // Create procedural memory table
    await db.execute('''
      CREATE TABLE $_proceduralMemoryTable (
        id TEXT PRIMARY KEY,
        pattern_type TEXT NOT NULL,
        rule_data TEXT NOT NULL,
        success_rate REAL NOT NULL DEFAULT 1.0,
        usage_count INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        last_used INTEGER NOT NULL,
        description TEXT,
        conditions TEXT
      )
    ''');

    // Create memory settings table
    await db.execute('''
      CREATE TABLE $_memorySettingsTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create simple memory tables
    await db.execute('''
      CREATE TABLE $_simpleUserMemoryTable (
        user_context TEXT PRIMARY KEY,
        facts TEXT NOT NULL DEFAULT '{}',
        updated_at INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $_simpleConversationMemoryTable (
        conversation_id TEXT PRIMARY KEY,
        topics TEXT NOT NULL DEFAULT '[]',
        created_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
        'CREATE INDEX idx_semantic_user_context ON $_semanticMemoryTable(user_context)');
    await db.execute(
        'CREATE INDEX idx_episodic_conversation_id ON $_episodicMemoryTable(conversation_id)');
    await db.execute(
        'CREATE INDEX idx_episodic_relevance_score ON $_episodicMemoryTable(relevance_score DESC)');
    await db.execute(
        'CREATE INDEX idx_episodic_created_at ON $_episodicMemoryTable(created_at DESC)');
    await db.execute(
        'CREATE INDEX idx_procedural_pattern_type ON $_proceduralMemoryTable(pattern_type)');
    await db.execute(
        'CREATE INDEX idx_procedural_success_rate ON $_proceduralMemoryTable(success_rate DESC)');
    await db.execute(
        'CREATE INDEX idx_procedural_last_used ON $_proceduralMemoryTable(last_used DESC)');
    
    // Create indexes for simple memory tables
    await db.execute(
        'CREATE INDEX idx_simple_conversation_created_at ON $_simpleConversationMemoryTable(created_at DESC)');
  }

  /// Handle database upgrades
  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // Handle future database schema upgrades here
    if (oldVersion < newVersion) {
      // Add migration logic for future versions
      await _migrateToSimpleMemory(db);
    }
  }

  /// Migrate existing database to include simple memory tables
  static Future<void> _migrateToSimpleMemory(Database db) async {
    try {
      // Check if simple memory tables already exist
      final List<Map<String, dynamic>> tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('simple_user_memory', 'simple_conversation_memory')"
      );
      
      if (tables.length < 2) {
        // Create simple memory tables if they don't exist
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_simpleUserMemoryTable (
            user_context TEXT PRIMARY KEY,
            facts TEXT NOT NULL DEFAULT '{}',
            updated_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS $_simpleConversationMemoryTable (
            conversation_id TEXT PRIMARY KEY,
            topics TEXT NOT NULL DEFAULT '[]',
            created_at INTEGER NOT NULL
          )
        ''');

        // Create indexes for simple memory tables
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_simple_conversation_created_at ON $_simpleConversationMemoryTable(created_at DESC)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('MemoryDatabase: Error migrating to simple memory: $e');
      }
    }
  }

  /// Ensure simple memory tables exist (for existing databases)
  static Future<void> ensureSimpleMemoryTables() async {
    final Database db = await database;
    await _migrateToSimpleMemory(db);
  }

  /// Close the database
  static Future<void> close() async {
    final Database? db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  /// Delete the database file (for testing or reset purposes)
  static Future<void> deleteDatabase() async {
    final String documentsDirectory = await getDatabasesPath();
    final String path = join(documentsDirectory, _databaseName);

    await close();

    final File file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // Semantic Memory Operations

  /// Insert or update semantic memory
  static Future<void> insertSemanticMemory(SemanticMemory memory) async {
    final Database db = await database;
    await db.insert(
      _semanticMemoryTable,
      memory.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get semantic memory by user context
  static Future<SemanticMemory?> getSemanticMemory(String userContext) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _semanticMemoryTable,
      where: 'user_context = ?',
      whereArgs: <Object?>[userContext],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return SemanticMemory.fromMap(maps.first);
    }
    return null;
  }

  /// Get all semantic memories
  static Future<List<SemanticMemory>> getAllSemanticMemories() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query(_semanticMemoryTable);
    return maps
        .map((Map<String, dynamic> map) => SemanticMemory.fromMap(map))
        .toList();
  }

  /// Delete semantic memory
  static Future<void> deleteSemanticMemory(String id) async {
    final Database db = await database;
    await db.delete(
      _semanticMemoryTable,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  // Episodic Memory Operations

  /// Insert episodic memory
  static Future<void> insertEpisodicMemory(EpisodicMemory memory) async {
    final Database db = await database;
    await db.insert(
      _episodicMemoryTable,
      memory.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get episodic memories by conversation ID
  static Future<List<EpisodicMemory>> getEpisodicMemoriesByConversation(
      String conversationId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _episodicMemoryTable,
      where: 'conversation_id = ?',
      whereArgs: <Object?>[conversationId],
      orderBy: 'created_at DESC',
    );
    return maps
        .map((Map<String, dynamic> map) => EpisodicMemory.fromMap(map))
        .toList();
  }

  /// Get top episodic memories by relevance score
  static Future<List<EpisodicMemory>> getTopEpisodicMemories(
      {int limit = 10}) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _episodicMemoryTable,
      orderBy: 'relevance_score DESC, created_at DESC',
      limit: limit,
    );
    return maps
        .map((Map<String, dynamic> map) => EpisodicMemory.fromMap(map))
        .toList();
  }

  /// Search episodic memories by tags
  static Future<List<EpisodicMemory>> searchEpisodicMemoriesByTags(
      List<String> tags) async {
    final Database db = await database;
    final String tagConditions =
        tags.map((String tag) => "tags LIKE '%\"$tag\"%'").join(' OR ');

    final List<Map<String, dynamic>> maps = await db.query(
      _episodicMemoryTable,
      where: tagConditions,
      orderBy: 'relevance_score DESC, created_at DESC',
    );
    return maps
        .map((Map<String, dynamic> map) => EpisodicMemory.fromMap(map))
        .toList();
  }

  /// Get all episodic memories
  static Future<List<EpisodicMemory>> getAllEpisodicMemories() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _episodicMemoryTable,
      orderBy: 'created_at DESC',
    );
    return maps
        .map((Map<String, dynamic> map) => EpisodicMemory.fromMap(map))
        .toList();
  }

  /// Delete episodic memory
  static Future<void> deleteEpisodicMemory(String id) async {
    final Database db = await database;
    await db.delete(
      _episodicMemoryTable,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  /// Delete old episodic memories (older than specified days)
  static Future<int> deleteOldEpisodicMemories(int daysOld) async {
    final Database db = await database;
    final int cutoffTime =
        DateTime.now().subtract(Duration(days: daysOld)).millisecondsSinceEpoch;

    return await db.delete(
      _episodicMemoryTable,
      where: 'created_at < ?',
      whereArgs: <Object?>[cutoffTime],
    );
  }

  // Procedural Memory Operations

  /// Insert procedural memory
  static Future<void> insertProceduralMemory(ProceduralMemory memory) async {
    final Database db = await database;
    await db.insert(
      _proceduralMemoryTable,
      memory.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get procedural memories by pattern type
  static Future<List<ProceduralMemory>> getProceduralMemoriesByType(
      String patternType) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _proceduralMemoryTable,
      where: 'pattern_type = ?',
      whereArgs: <Object?>[patternType],
      orderBy: 'success_rate DESC, usage_count DESC',
    );
    return maps
        .map((Map<String, dynamic> map) => ProceduralMemory.fromMap(map))
        .toList();
  }

  /// Get top procedural memories by success rate
  static Future<List<ProceduralMemory>> getTopProceduralMemories(
      {int limit = 10}) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _proceduralMemoryTable,
      orderBy: 'success_rate DESC, usage_count DESC',
      limit: limit,
    );
    return maps
        .map((Map<String, dynamic> map) => ProceduralMemory.fromMap(map))
        .toList();
  }

  /// Get all procedural memories
  static Future<List<ProceduralMemory>> getAllProceduralMemories() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _proceduralMemoryTable,
      orderBy: 'success_rate DESC',
    );
    return maps
        .map((Map<String, dynamic> map) => ProceduralMemory.fromMap(map))
        .toList();
  }

  /// Delete procedural memory
  static Future<void> deleteProceduralMemory(String id) async {
    final Database db = await database;
    await db.delete(
      _proceduralMemoryTable,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );
  }

  // Memory Settings Operations

  /// Set memory setting
  static Future<void> setMemorySetting(String key, String value) async {
    final Database db = await database;
    await db.insert(
      _memorySettingsTable,
      <String, Object?>{
        'key': key,
        'value': value,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get memory setting
  static Future<String?> getMemorySetting(String key) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _memorySettingsTable,
      where: 'key = ?',
      whereArgs: <Object?>[key],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  /// Get all memory settings
  static Future<Map<String, String>> getAllMemorySettings() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query(_memorySettingsTable);

    final Map<String, String> settings = <String, String>{};
    for (final Map<String, dynamic> map in maps) {
      settings[map['key'] as String] = map['value'] as String;
    }
    return settings;
  }

  // Statistics and Maintenance

  /// Get memory statistics
  static Future<Map<String, int>> getMemoryStatistics() async {
    final Database db = await database;

    final int semanticCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $_semanticMemoryTable'),
        ) ??
        0;

    final int episodicCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $_episodicMemoryTable'),
        ) ??
        0;

    final int proceduralCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $_proceduralMemoryTable'),
        ) ??
        0;

    return <String, int>{
      'semantic': semanticCount,
      'episodic': episodicCount,
      'procedural': proceduralCount,
      'total': semanticCount + episodicCount + proceduralCount,
    };
  }

  /// Clear all memory data
  static Future<void> clearAllMemories() async {
    final Database db = await database;
    await db.delete(_semanticMemoryTable);
    await db.delete(_episodicMemoryTable);
    await db.delete(_proceduralMemoryTable);
  }

  /// Vacuum the database to reclaim space
  static Future<void> vacuum() async {
    final Database db = await database;
    await db.execute('VACUUM');
  }

  // Simple Memory Operations

  /// Insert or update simple user memory
  static Future<void> insertSimpleUserMemory(SimpleUserMemory memory) async {
    final Database db = await database;
    await db.insert(
      _simpleUserMemoryTable,
      memory.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get simple user memory by user context
  static Future<Map<String, dynamic>?> getSimpleUserMemory(String userContext) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _simpleUserMemoryTable,
      where: 'user_context = ?',
      whereArgs: <Object?>[userContext],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  /// Insert or update simple conversation memory
  static Future<void> insertSimpleConversationMemory(SimpleConversationMemory memory) async {
    final Database db = await database;
    await db.insert(
      _simpleConversationMemoryTable,
      memory.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get simple conversation memory by conversation ID
  static Future<Map<String, dynamic>?> getSimpleConversationMemory(String conversationId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _simpleConversationMemoryTable,
      where: 'conversation_id = ?',
      whereArgs: <Object?>[conversationId],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }

  /// Get recent simple conversation memories
  static Future<List<SimpleConversationMemory>> getRecentSimpleConversationMemories({int limit = 5}) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _simpleConversationMemoryTable,
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps
        .map((Map<String, dynamic> map) => SimpleConversationMemory.fromMap(map))
        .toList();
  }

  /// Delete old simple conversation memories (older than specified days)
  static Future<int> deleteOldSimpleConversationMemories({int olderThanDays = 90}) async {
    final Database db = await database;
    final int cutoffTime =
        DateTime.now().subtract(Duration(days: olderThanDays)).millisecondsSinceEpoch;

    return await db.delete(
      _simpleConversationMemoryTable,
      where: 'created_at < ?',
      whereArgs: <Object?>[cutoffTime],
    );
  }

  /// Clear all simple memory data
  static Future<void> clearAllSimpleMemories() async {
    final Database db = await database;
    await db.delete(_simpleUserMemoryTable);
    await db.delete(_simpleConversationMemoryTable);
  }

  /// Get simple memory statistics
  static Future<Map<String, int>> getSimpleMemoryStatistics() async {
    final Database db = await database;

    final int userMemoryCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $_simpleUserMemoryTable'),
        ) ??
        0;

    final int conversationMemoryCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM $_simpleConversationMemoryTable'),
        ) ??
        0;

    return <String, int>{
      'user_memories': userMemoryCount,
      'conversation_memories': conversationMemoryCount,
      'total': userMemoryCount + conversationMemoryCount,
    };
  }
}
