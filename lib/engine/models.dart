/// Data models for the ScamShield pattern engine.
///
/// Pure Dart — no Flutter imports — so the engine is testable in isolation.
library;

/// A single detection rule inside a [ScamPattern].
///
/// Two kinds of rules:
/// - `regex`: [pattern] is compiled as a case-insensitive regular expression.
/// - `keyword`: [pattern] is matched as a case-insensitive substring.
class Signal {
  const Signal({
    required this.label,
    required this.type,
    required this.pattern,
    required this.weight,
  });

  /// Human-readable description of what this signal detects.
  final String label;

  /// 'regex' or 'keyword'.
  final String type;

  /// The regex source or keyword string to match.
  final String pattern;

  /// Contribution to the pattern score when this signal fires.
  final double weight;

  factory Signal.fromJson(Map<String, dynamic> json) => Signal(
        label: json['label'] as String,
        type: json['type'] as String,
        pattern: json['pattern'] as String,
        weight: (json['weight'] as num).toDouble(),
      );

  /// Returns true if this signal fires on [text].
  bool matches(String text) {
    switch (type) {
      case 'regex':
        return RegExp(pattern, caseSensitive: false).hasMatch(text);
      case 'keyword':
        return text.toLowerCase().contains(pattern.toLowerCase());
      default:
        throw ArgumentError('Unknown signal type: $type');
    }
  }
}

/// A known scam pattern loaded from the bundled JSON database.
class ScamPattern {
  const ScamPattern({
    required this.id,
    required this.name,
    required this.category,
    required this.explanation,
    required this.advice,
    required this.signals,
  });

  final String id;
  final String name;
  final String category;
  final String explanation;
  final String advice;
  final List<Signal> signals;

  factory ScamPattern.fromJson(Map<String, dynamic> json) => ScamPattern(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        explanation: json['explanation'] as String,
        advice: json['advice'] as String,
        signals: (json['signals'] as List<dynamic>)
            .map((s) => Signal.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

/// The result of matching one [ScamPattern] against input text.
class MatchResult {
  const MatchResult({
    required this.patternId,
    required this.name,
    required this.category,
    required this.score,
    required this.matchedSignals,
    required this.explanation,
    required this.advice,
  });

  final String patternId;
  final String name;
  final String category;

  /// Heuristic score in [0, 1]: sum of fired signal weights, clamped to 1.
  final double score;

  /// Labels of the signals that fired.
  final List<String> matchedSignals;

  final String explanation;
  final String advice;

  /// Severity band derived from [score], used for UI color coding.
  Severity get severity {
    if (score >= 0.6) return Severity.high;
    if (score >= 0.35) return Severity.medium;
    return Severity.low;
  }

  Map<String, dynamic> toJson() => {
        'pattern_id': patternId,
        'name': name,
        'category': category,
        'score': score,
        'matched_signals': matchedSignals,
        'explanation': explanation,
        'advice': advice,
      };
}

enum Severity { high, medium, low }
