import 'dart:convert';

import 'memory_base.dart';

/// Semantic memory stores facts, knowledge, and user preferences.
/// This follows the LangMem profile-based storage pattern where information
/// is consolidated into a single document that represents the current state.
class SemanticMemory extends MemoryBase {
  /// Unique identifier for this semantic memory entry
  @override
  final String id;

  /// Context identifier (e.g., user ID, session context)
  final String userContext;

  /// Profile data containing facts, preferences, and knowledge
  final Map<String, dynamic> profileData;

  /// When this memory was first created
  @override
  final DateTime createdAt;

  /// When this memory was last updated
  final DateTime updatedAt;

  /// Version number for tracking updates
  final int version;

  SemanticMemory({
    required this.id,
    required this.userContext,
    required this.profileData,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  /// Create a new semantic memory with initial data
  factory SemanticMemory.create({
    required String id,
    required String userContext,
    required Map<String, dynamic> profileData,
  }) {
    final DateTime now = DateTime.now();
    return SemanticMemory(
      id: id,
      userContext: userContext,
      profileData: profileData,
      createdAt: now,
      updatedAt: now,
      version: 1,
    );
  }

  /// Create semantic memory from database map
  factory SemanticMemory.fromMap(Map<String, dynamic> map) {
    return SemanticMemory(
      id: map['id'] as String,
      userContext: map['user_context'] as String,
      profileData:
          jsonDecode(map['profile_data'] as String) as Map<String, dynamic>,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
      version: map['version'] as int,
    );
  }

  /// Convert to database map
  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'user_context': userContext,
      'profile_data': jsonEncode(profileData),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'version': version,
    };
  }

  /// Create an updated copy with new profile data
  SemanticMemory copyWith({
    String? id,
    String? userContext,
    Map<String, dynamic>? profileData,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
  }) {
    return SemanticMemory(
      id: id ?? this.id,
      userContext: userContext ?? this.userContext,
      profileData: profileData ?? this.profileData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  /// Update this memory with new data, incrementing version
  SemanticMemory update(Map<String, dynamic> newData) {
    final Map<String, dynamic> updatedProfileData =
        Map<String, dynamic>.from(profileData);

    // Merge new data with existing profile data
    newData.forEach((String key, dynamic value) {
      updatedProfileData[key] = value;
    });

    return copyWith(
      profileData: updatedProfileData,
      updatedAt: DateTime.now(),
      version: version + 1,
    );
  }

  /// Get a specific fact or preference from the profile
  T? get<T>(String key) {
    return profileData[key] as T?;
  }

  /// Check if a specific key exists in the profile
  bool contains(String key) {
    return profileData.containsKey(key);
  }

  @override
  String toString() {
    return 'SemanticMemory(id: $id, userContext: $userContext, version: $version, profileData: ${profileData.keys.toList()})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SemanticMemory &&
        other.id == id &&
        other.userContext == userContext &&
        other.version == version;
  }

  @override
  int get hashCode {
    return id.hashCode ^ userContext.hashCode ^ version.hashCode;
  }
}
