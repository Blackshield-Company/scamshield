/// Loads the bundled scam pattern database (assets/patterns.json).
///
/// Pure Dart — accepts the JSON string directly so it can be tested without
/// Flutter's asset system.
library;

import 'dart:convert';

import 'models.dart';

class PatternDatabase {
  PatternDatabase(this.patterns);

  final List<ScamPattern> patterns;

  /// Parse a database from raw JSON text.
  factory PatternDatabase.fromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final list = decoded['patterns'] as List<dynamic>;
    return PatternDatabase(
      list
          .map((p) => ScamPattern.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Parse from an already-decoded map.
  factory PatternDatabase.fromJson(Map<String, dynamic> json) {
    final list = json['patterns'] as List<dynamic>;
    return PatternDatabase(
      list
          .map((p) => ScamPattern.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  int get length => patterns.length;
}
