/// Base class for all memory types providing common functionality
abstract class MemoryBase {
  /// Unique identifier for this memory entry
  String get id;

  /// When this memory was created
  DateTime get createdAt;

  /// Convert to database map
  Map<String, dynamic> toMap();

  /// Get the age of this memory in days
  int get ageInDays {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Get the age of this memory in hours
  int get ageInHours {
    return DateTime.now().difference(createdAt).inHours;
  }

  /// Check if this memory is recent (less than 24 hours old)
  bool get isRecent {
    return ageInHours < 24;
  }

  /// Check if this memory is old (more than 30 days old)
  bool get isOld {
    return ageInDays > 30;
  }
}

/// Enum for different memory types
enum MemoryType {
  semantic,
  episodic,
  procedural,
}

/// Extension to get string representation of memory types
extension MemoryTypeExtension on MemoryType {
  String get name {
    switch (this) {
      case MemoryType.semantic:
        return 'semantic';
      case MemoryType.episodic:
        return 'episodic';
      case MemoryType.procedural:
        return 'procedural';
    }
  }

  static MemoryType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'semantic':
        return MemoryType.semantic;
      case 'episodic':
        return MemoryType.episodic;
      case 'procedural':
        return MemoryType.procedural;
      default:
        throw ArgumentError('Unknown memory type: $value');
    }
  }
}

/// Memory statistics for tracking usage and performance
class MemoryStats {
  final int totalMemories;
  final int semanticCount;
  final int episodicCount;
  final int proceduralCount;
  final DateTime? lastUpdated;
  final int totalRetrievals;
  final double averageRelevanceScore;

  MemoryStats({
    required this.totalMemories,
    required this.semanticCount,
    required this.episodicCount,
    required this.proceduralCount,
    this.lastUpdated,
    required this.totalRetrievals,
    required this.averageRelevanceScore,
  });

  factory MemoryStats.empty() {
    return MemoryStats(
      totalMemories: 0,
      semanticCount: 0,
      episodicCount: 0,
      proceduralCount: 0,
      totalRetrievals: 0,
      averageRelevanceScore: 0.0,
    );
  }

  @override
  String toString() {
    return 'MemoryStats(total: $totalMemories, semantic: $semanticCount, episodic: $episodicCount, procedural: $proceduralCount, retrievals: $totalRetrievals, avgRelevance: ${averageRelevanceScore.toStringAsFixed(2)})';
  }
}
