import 'dart:convert';

import 'memory_base.dart';

/// Procedural memory stores system behavior patterns and response styles.
/// This follows the LangMem rule-based storage pattern where behavioral
/// patterns and successful approaches are stored as reusable rules.
class ProceduralMemory extends MemoryBase {
  /// Unique identifier for this procedural memory entry
  @override
  final String id;

  /// Type of pattern (e.g., 'response_style', 'prompt_pattern', 'behavior_rule')
  final String patternType;

  /// The rule or pattern data
  final Map<String, dynamic> ruleData;

  /// Success rate of this pattern (0.0 to 1.0)
  final double successRate;

  /// Number of times this pattern has been used
  final int usageCount;

  /// When this pattern was first created
  @override
  final DateTime createdAt;

  /// When this pattern was last used
  final DateTime lastUsed;

  /// Optional description of the pattern
  final String? description;

  /// Conditions under which this pattern should be applied
  final Map<String, dynamic>? conditions;

  ProceduralMemory({
    required this.id,
    required this.patternType,
    required this.ruleData,
    required this.successRate,
    required this.usageCount,
    required this.createdAt,
    required this.lastUsed,
    this.description,
    this.conditions,
  });

  /// Create a new procedural memory
  factory ProceduralMemory.create({
    required String id,
    required String patternType,
    required Map<String, dynamic> ruleData,
    double successRate = 1.0,
    String? description,
    Map<String, dynamic>? conditions,
  }) {
    final DateTime now = DateTime.now();
    return ProceduralMemory(
      id: id,
      patternType: patternType,
      ruleData: ruleData,
      successRate: successRate,
      usageCount: 1,
      createdAt: now,
      lastUsed: now,
      description: description,
      conditions: conditions,
    );
  }

  /// Create procedural memory from database map
  factory ProceduralMemory.fromMap(Map<String, dynamic> map) {
    return ProceduralMemory(
      id: map['id'] as String,
      patternType: map['pattern_type'] as String,
      ruleData: jsonDecode(map['rule_data'] as String) as Map<String, dynamic>,
      successRate: (map['success_rate'] as num).toDouble(),
      usageCount: map['usage_count'] as int,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      lastUsed: DateTime.fromMillisecondsSinceEpoch(map['last_used'] as int),
      description: map['description'] as String?,
      conditions: map['conditions'] != null
          ? jsonDecode(map['conditions'] as String) as Map<String, dynamic>
          : null,
    );
  }

  /// Convert to database map
  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'pattern_type': patternType,
      'rule_data': jsonEncode(ruleData),
      'success_rate': successRate,
      'usage_count': usageCount,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_used': lastUsed.millisecondsSinceEpoch,
      'description': description,
      'conditions': conditions != null ? jsonEncode(conditions) : null,
    };
  }

  /// Create a copy with updated values
  ProceduralMemory copyWith({
    String? id,
    String? patternType,
    Map<String, dynamic>? ruleData,
    double? successRate,
    int? usageCount,
    DateTime? createdAt,
    DateTime? lastUsed,
    String? description,
    Map<String, dynamic>? conditions,
  }) {
    return ProceduralMemory(
      id: id ?? this.id,
      patternType: patternType ?? this.patternType,
      ruleData: ruleData ?? this.ruleData,
      successRate: successRate ?? this.successRate,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      lastUsed: lastUsed ?? this.lastUsed,
      description: description ?? this.description,
      conditions: conditions ?? this.conditions,
    );
  }

  /// Record a successful use of this pattern
  ProceduralMemory recordSuccess() {
    final int newUsageCount = usageCount + 1;
    final double newSuccessRate =
        ((successRate * usageCount) + 1.0) / newUsageCount;

    return copyWith(
      successRate: newSuccessRate,
      usageCount: newUsageCount,
      lastUsed: DateTime.now(),
    );
  }

  /// Record a failed use of this pattern
  ProceduralMemory recordFailure() {
    final int newUsageCount = usageCount + 1;
    final double newSuccessRate = (successRate * usageCount) / newUsageCount;

    return copyWith(
      successRate: newSuccessRate,
      usageCount: newUsageCount,
      lastUsed: DateTime.now(),
    );
  }

  /// Update the pattern with new rule data
  ProceduralMemory updateRule(Map<String, dynamic> newRuleData) {
    return copyWith(
      ruleData: newRuleData,
      lastUsed: DateTime.now(),
    );
  }

  /// Check if this pattern should be applied based on conditions
  bool shouldApply(Map<String, dynamic> context) {
    if (conditions == null) return true;

    // Check each condition against the context
    for (final MapEntry<String, dynamic> entry in conditions!.entries) {
      final String key = entry.key;
      final dynamic expectedValue = entry.value;

      if (!context.containsKey(key)) return false;

      final dynamic actualValue = context[key];
      if (actualValue != expectedValue) return false;
    }

    return true;
  }

  /// Get the effectiveness score based on success rate and usage frequency
  double get effectivenessScore {
    // Combine success rate with usage frequency
    // More frequently used patterns with high success rates get higher scores
    final double frequencyBonus = (usageCount / 100.0).clamp(0.0, 1.0);
    return (successRate * 0.8) + (frequencyBonus * 0.2);
  }

  /// Get the recency score based on when this pattern was last used
  double get recencyScore {
    final int daysSinceLastUse = DateTime.now().difference(lastUsed).inDays;
    // Patterns used recently get higher scores
    return 1.0 / (1.0 + daysSinceLastUse * 0.1);
  }

  /// Get the overall pattern score combining effectiveness and recency
  double get overallScore {
    return (effectivenessScore * 0.7) + (recencyScore * 0.3);
  }

  /// Check if this pattern is similar to another based on rule data
  bool isSimilarTo(ProceduralMemory other, {double threshold = 0.6}) {
    if (patternType != other.patternType) return false;

    // Simple similarity check based on common keys in rule data
    final Set<String> thisKeys = ruleData.keys.toSet();
    final Set<String> otherKeys = other.ruleData.keys.toSet();

    final Set<String> intersection = thisKeys.intersection(otherKeys);
    final Set<String> union = thisKeys.union(otherKeys);

    if (union.isEmpty) return false;

    final double similarity = intersection.length / union.length;
    return similarity >= threshold;
  }

  /// Get a specific rule value
  T? getRule<T>(String key) {
    return ruleData[key] as T?;
  }

  /// Check if a specific rule exists
  bool hasRule(String key) {
    return ruleData.containsKey(key);
  }

  @override
  String toString() {
    return 'ProceduralMemory(id: $id, patternType: $patternType, successRate: ${successRate.toStringAsFixed(2)}, usageCount: $usageCount, effectivenessScore: ${effectivenessScore.toStringAsFixed(2)})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProceduralMemory &&
        other.id == id &&
        other.patternType == patternType;
  }

  @override
  int get hashCode {
    return id.hashCode ^ patternType.hashCode;
  }
}
