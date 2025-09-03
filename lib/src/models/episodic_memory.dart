import 'dart:convert';

import 'memory_base.dart';

/// Episodic memory stores past conversation experiences and summaries.
/// This follows the LangMem collection-based storage pattern where each
/// conversation or experience is stored as an individual record.
class EpisodicMemory extends MemoryBase {
  /// Unique identifier for this episodic memory entry
  @override
  final String id;

  /// Identifier for the conversation this memory belongs to
  final String conversationId;

  /// Summary of the conversation or experience
  final String summary;

  /// Additional context about the conversation
  final String context;

  /// Relevance score for this memory (0.0 to 1.0)
  final double relevanceScore;

  /// When this memory was created
  @override
  final DateTime createdAt;

  /// Tags for categorizing and searching memories
  final List<String> tags;

  /// Optional metadata for additional information
  final Map<String, dynamic>? metadata;

  EpisodicMemory({
    required this.id,
    required this.conversationId,
    required this.summary,
    required this.context,
    required this.relevanceScore,
    required this.createdAt,
    required this.tags,
    this.metadata,
  });

  /// Create a new episodic memory
  factory EpisodicMemory.create({
    required String id,
    required String conversationId,
    required String summary,
    required String context,
    double relevanceScore = 1.0,
    List<String> tags = const <String>[],
    Map<String, dynamic>? metadata,
  }) {
    return EpisodicMemory(
      id: id,
      conversationId: conversationId,
      summary: summary,
      context: context,
      relevanceScore: relevanceScore,
      createdAt: DateTime.now(),
      tags: tags,
      metadata: metadata,
    );
  }

  /// Create episodic memory from database map
  factory EpisodicMemory.fromMap(Map<String, dynamic> map) {
    return EpisodicMemory(
      id: map['id'] as String,
      conversationId: map['conversation_id'] as String,
      summary: map['summary'] as String,
      context: map['context'] as String,
      relevanceScore: (map['relevance_score'] as num).toDouble(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      tags: (jsonDecode(map['tags'] as String) as List<dynamic>).cast<String>(),
      metadata: map['metadata'] != null
          ? jsonDecode(map['metadata'] as String) as Map<String, dynamic>
          : null,
    );
  }

  /// Convert to database map
  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'conversation_id': conversationId,
      'summary': summary,
      'context': context,
      'relevance_score': relevanceScore,
      'created_at': createdAt.millisecondsSinceEpoch,
      'tags': jsonEncode(tags),
      'metadata': metadata != null ? jsonEncode(metadata) : null,
    };
  }

  /// Create a copy with updated values
  EpisodicMemory copyWith({
    String? id,
    String? conversationId,
    String? summary,
    String? context,
    double? relevanceScore,
    DateTime? createdAt,
    List<String>? tags,
    Map<String, dynamic>? metadata,
  }) {
    return EpisodicMemory(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      summary: summary ?? this.summary,
      context: context ?? this.context,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Update the relevance score based on usage and time decay
  EpisodicMemory updateRelevanceScore(double newScore) {
    return copyWith(relevanceScore: newScore);
  }

  /// Add tags to this memory
  EpisodicMemory addTags(List<String> newTags) {
    final List<String> updatedTags = List<String>.from(tags);
    for (final String tag in newTags) {
      if (!updatedTags.contains(tag)) {
        updatedTags.add(tag);
      }
    }
    return copyWith(tags: updatedTags);
  }

  /// Check if this memory contains a specific tag
  bool hasTag(String tag) {
    return tags.contains(tag);
  }

  /// Check if this memory matches any of the given tags
  bool hasAnyTag(List<String> searchTags) {
    return searchTags.any((String tag) => tags.contains(tag));
  }

  /// Get the age of this memory in days
  @override
  int get ageInDays {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Calculate time-decayed relevance score
  double get timeDecayedRelevance {
    final int daysSinceCreation = ageInDays;
    // Apply exponential decay: score * e^(-decay_rate * days)
    const double decayRate = 0.01; // Adjust this value to control decay speed
    return relevanceScore * (1.0 / (1.0 + decayRate * daysSinceCreation));
  }

  /// Check if this memory is similar to another based on content
  bool isSimilarTo(EpisodicMemory other, {double threshold = 0.7}) {
    // Simple similarity check based on common words in summary
    final Set<String> thisWords = summary.toLowerCase().split(' ').toSet();
    final Set<String> otherWords =
        other.summary.toLowerCase().split(' ').toSet();

    final Set<String> intersection = thisWords.intersection(otherWords);
    final Set<String> union = thisWords.union(otherWords);

    final double similarity = intersection.length / union.length;
    return similarity >= threshold;
  }

  @override
  String toString() {
    return 'EpisodicMemory(id: $id, conversationId: $conversationId, summary: ${summary.length > 50 ? '${summary.substring(0, 50)}...' : summary}, relevanceScore: $relevanceScore, tags: $tags)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EpisodicMemory &&
        other.id == id &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    return id.hashCode ^ conversationId.hashCode;
  }
}
