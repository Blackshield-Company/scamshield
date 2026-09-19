/// Scores input text against every pattern in a [PatternDatabase].
///
/// Pure Dart — no Flutter imports.
///
/// Scoring model (heuristic, not statistical):
/// - Each signal that fires contributes its weight.
/// - Pattern score = sum of fired weights, clamped to [0, 1].
/// - Patterns scoring below [minScore] are dropped from the results.
/// - Results are sorted by descending score.
library;

import 'models.dart';
import 'pattern_database.dart';

class Matcher {
  const Matcher(this.database, {this.minScore = 0.15});

  final PatternDatabase database;

  /// Patterns with a score below this threshold are not reported.
  final double minScore;

  /// Analyze [text] and return all matching patterns, highest score first.
  ///
  /// Empty or whitespace-only input returns an empty list.
  List<MatchResult> analyze(String text) {
    if (text.trim().isEmpty) return const [];

    final results = <MatchResult>[];
    for (final pattern in database.patterns) {
      double score = 0;
      final fired = <String>[];
      for (final signal in pattern.signals) {
        if (signal.matches(text)) {
          score += signal.weight;
          fired.add(signal.label);
        }
      }
      score = score.clamp(0.0, 1.0);
      if (score >= minScore && fired.isNotEmpty) {
        results.add(
          MatchResult(
            patternId: pattern.id,
            name: pattern.name,
            category: pattern.category,
            score: score,
            matchedSignals: fired,
            explanation: pattern.explanation,
            advice: pattern.advice,
          ),
        );
      }
    }
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }
}
