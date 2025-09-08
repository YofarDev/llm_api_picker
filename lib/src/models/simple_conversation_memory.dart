import 'dart:convert';

/// Simplified conversation memory that stores only basic topics discussed
/// Replaces the complex EpisodicMemory with simple topic tracking
class SimpleConversationMemory {
  /// Identifier for the conversation
  final String conversationId;

  /// Simple list of topics discussed in this conversation
  /// Examples: ["weather", "programming", "food", "travel"]
  final List<String> topics;

  /// When this conversation memory was created
  final DateTime createdAt;

  SimpleConversationMemory({
    required this.conversationId,
    required this.topics,
    required this.createdAt,
  });

  /// Create a new conversation memory
  factory SimpleConversationMemory.create({
    required String conversationId,
    List<String>? topics,
  }) {
    return SimpleConversationMemory(
      conversationId: conversationId,
      topics: topics ?? <String>[],
      createdAt: DateTime.now(),
    );
  }

  /// Create from database map
  factory SimpleConversationMemory.fromMap(Map<String, dynamic> map) {
    List<String> topics = <String>[];
    
    // Handle JSON string from database
    if (map['topics'] is String) {
      try {
        final List<dynamic> decodedTopics = jsonDecode(map['topics'] as String) as List<dynamic>;
        topics = decodedTopics.cast<String>();
      } catch (e) {
        // If JSON decode fails, use empty list
        topics = <String>[];
      }
    } else if (map['topics'] is List) {
      topics = List<String>.from(map['topics'] as List);
    }
    
    return SimpleConversationMemory(
      conversationId: map['conversation_id'] as String,
      topics: topics,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Convert to database map
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'conversation_id': conversationId,
      'topics': jsonEncode(topics),
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Add new topics to this conversation
  SimpleConversationMemory addTopics(List<String> newTopics) {
    final List<String> updatedTopics = List<String>.from(topics);
    
    // Add only unique topics
    for (final String topic in newTopics) {
      if (!updatedTopics.contains(topic)) {
        updatedTopics.add(topic);
      }
    }

    return SimpleConversationMemory(
      conversationId: conversationId,
      topics: updatedTopics,
      createdAt: createdAt,
    );
  }

  /// Check if this conversation discussed a specific topic
  bool hasTopic(String topic) {
    return topics.contains(topic);
  }

  /// Get topics as a readable string
  String getTopicsAsString() {
    if (topics.isEmpty) return '';
    return topics.join(', ');
  }

  /// Get the age of this conversation in days
  int get ageInDays {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Check if this conversation is recent (within last 7 days)
  bool get isRecent {
    return ageInDays <= 7;
  }

  @override
  String toString() {
    return 'SimpleConversationMemory(conversationId: $conversationId, topics: $topics)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SimpleConversationMemory &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    return conversationId.hashCode;
  }
}