import 'dart:convert';

/// Simplified user memory that stores only essential facts about the user
/// Replaces the complex SemanticMemory with a simple key-value store
class SimpleUserMemory {
  /// Context identifier (e.g., user ID, session context)
  final String userContext;

  /// Simple key-value facts about the user
  /// Examples: {"name": "John", "food_likes": "pizza", "location": "Paris"}
  final Map<String, String> facts;

  /// When this memory was last updated
  final DateTime updatedAt;

  SimpleUserMemory({
    required this.userContext,
    required this.facts,
    required this.updatedAt,
  });

  /// Create a new user memory
  factory SimpleUserMemory.create({
    required String userContext,
    Map<String, String>? facts,
  }) {
    return SimpleUserMemory(
      userContext: userContext,
      facts: facts ?? <String, String>{},
      updatedAt: DateTime.now(),
    );
  }

  /// Create from database map
  factory SimpleUserMemory.fromMap(Map<String, dynamic> map) {
    Map<String, String> facts = <String, String>{};
    
    // Handle JSON string from database
    if (map['facts'] is String) {
      try {
        final Map<String, dynamic> decodedFacts = jsonDecode(map['facts'] as String) as Map<String, dynamic>;
        facts = Map<String, String>.from(decodedFacts);
      } catch (e) {
        // If JSON decode fails, use empty map
        facts = <String, String>{};
      }
    } else if (map['facts'] is Map) {
      facts = Map<String, String>.from(map['facts'] as Map);
    }
    
    return SimpleUserMemory(
      userContext: map['user_context'] as String,
      facts: facts,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'user_context': userContext,
      'facts': jsonEncode(facts),
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  /// Update with new facts
  SimpleUserMemory updateFacts(Map<String, String> newFacts) {
    final Map<String, String> updatedFacts = Map<String, String>.from(facts);
    updatedFacts.addAll(newFacts);

    return SimpleUserMemory(
      userContext: userContext,
      facts: updatedFacts,
      updatedAt: DateTime.now(),
    );
  }

  /// Get a specific fact
  String? getFact(String key) {
    return facts[key];
  }

  /// Check if a fact exists
  bool hasFact(String key) {
    return facts.containsKey(key);
  }

  /// Get all facts as a readable string
  String getFactsAsString() {
    if (facts.isEmpty) return '';
    
    return facts.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
  }

  @override
  String toString() {
    return 'SimpleUserMemory(userContext: $userContext, facts: $facts)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SimpleUserMemory &&
        other.userContext == userContext;
  }

  @override
  int get hashCode {
    return userContext.hashCode;
  }
}