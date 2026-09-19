import 'dart:io';

import 'package:flutter_test/flutter_test.dart' hide Matcher;
import 'package:scamshield/engine/engine.dart';

Matcher buildMatcher() {
  final json = File('assets/patterns.json').readAsStringSync();
  return Matcher(PatternDatabase.fromJsonString(json));
}

void main() {
  late Matcher matcher;

  setUpAll(() {
    matcher = buildMatcher();
  });

  group('PatternDatabase', () {
    test('bundled database loads with at least 12 patterns', () {
      final db = PatternDatabase.fromJsonString(
        File('assets/patterns.json').readAsStringSync(),
      );
      expect(db.length, greaterThanOrEqualTo(12));
    });

    test('every pattern has explanation, advice, and weighted signals', () {
      final db = PatternDatabase.fromJsonString(
        File('assets/patterns.json').readAsStringSync(),
      );
      for (final p in db.patterns) {
        expect(p.explanation, isNotEmpty, reason: p.id);
        expect(p.advice, isNotEmpty, reason: p.id);
        expect(p.signals, isNotEmpty, reason: p.id);
        for (final s in p.signals) {
          expect(s.weight, greaterThan(0), reason: '${p.id}/${s.label}');
        }
      }
    });
  });

  group('Matcher — known scam samples', () {
    test('grandparent scam text matches grandparent category', () {
      const sample = "Grandma, it's me, your grandson. I've been arrested "
          "and I'm in jail. I need money right away for bail. "
          "Please don't tell mom and dad — keep this a secret. "
          'Buy gift cards and the bail bondsman will call you.';
      final results = matcher.analyze(sample);
      expect(results, isNotEmpty);
      expect(results.first.patternId, 'grandparent-emergency');
      expect(results.first.category, 'Grandparent scam');
      expect(results.first.matchedSignals, isNotEmpty);
    });

    test('IRS impersonation text matches IRS/tax category', () {
      const sample = 'This is the IRS. There is an arrest warrant issued '
          'for unpaid taxes. Pay immediately within 24 hours using gift '
          'cards or federal agents will take legal action.';
      final results = matcher.analyze(sample);
      expect(results, isNotEmpty);
      expect(results.first.patternId, 'irs-tax-impersonation');
      expect(results.first.category, 'IRS/tax impersonation');
    });

    test('package delivery phishing text matches delivery category', () {
      const sample = 'USPS: your package was undeliverable and is on hold. '
          'Click here to reschedule and pay a small redelivery fee within '
          '24 hours or the parcel will be returned.';
      final results = matcher.analyze(sample);
      expect(results, isNotEmpty);
      expect(results.first.patternId, 'package-delivery-phishing');
      expect(results.first.category, 'Package delivery phishing');
    });

    test('sextortion text matches sextortion category', () {
      const sample = 'I hacked your device and recorded you through your '
          'webcam. I have compromising video. Pay in bitcoin within 48 '
          'hours or I will send the video to all your contacts.';
      final results = matcher.analyze(sample);
      expect(results, isNotEmpty);
      expect(results.first.patternId, 'sextortion');
      expect(results.first.category, 'Sextortion');
    });
  });

  group('Matcher — clean and empty input', () {
    test('clean everyday text produces no matches', () {
      const sample = 'Hi, just checking in. Would you like to come over for '
          'lunch on Saturday? The garden is looking lovely this week and '
          'the weather should be nice.';
      expect(matcher.analyze(sample), isEmpty);
    });

    test('empty input returns empty list', () {
      expect(matcher.analyze(''), isEmpty);
      expect(matcher.analyze('   \n\t '), isEmpty);
    });
  });

  group('Matcher — scoring and ranking', () {
    test('scores are clamped to [0, 1]', () {
      // Hits nearly every grandparent signal.
      const sample = "Grandma it's me, your grandson. I've been arrested, "
          "I'm in jail after a car accident and need money right now, "
          "as soon as possible. Don't tell mom, keep this a secret. "
          'Send gift cards via the bail bondsman courier.';
      final results = matcher.analyze(sample);
      for (final r in results) {
        expect(r.score, greaterThan(0));
        expect(r.score, lessThanOrEqualTo(1.0));
      }
      expect(results.first.score, 1.0);
    });

    test('stronger scam text ranks above weaker ambiguous text', () {
      const strong = "Grandma, it's me, your grandson. I'm in jail, I need "
          "money right away for bail, don't tell mom, keep it a secret, "
          'send gift cards.';
      const weak = 'Please donate to our flood relief fundraiser today.';
      final strongScore = matcher.analyze(strong).first.score;
      final weakResults = matcher.analyze(weak);
      final weakScore = weakResults.isEmpty ? 0.0 : weakResults.first.score;
      expect(strongScore, greaterThan(weakScore));
    });

    test('results are sorted by descending score', () {
      const sample = 'Congratulations, you have won the lottery jackpot! '
          'Pay the processing fee to claim your prize now. We accept '
          'bitcoin and gift cards for the tax on your winnings.';
      final results = matcher.analyze(sample);
      for (var i = 0; i + 1 < results.length; i++) {
        expect(results[i].score, greaterThanOrEqualTo(results[i + 1].score));
      }
      expect(results.first.patternId, 'lottery-sweepstakes');
    });
  });
}
