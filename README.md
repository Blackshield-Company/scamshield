# ScamShield

An offline, open-source scam pattern detector for Android and iOS, built to help
protect elderly people and their families from fraud.

Paste a suspicious text message, email, or the script a caller read to you —
ScamShield checks it against a database of known scam patterns right on the
device, flags what it finds, and explains in plain language what the scam is
and what to do next.

## Who it's for

- **Older adults** who receive suspicious calls, texts, or emails and want a
  quick, private second opinion.
- **Family members and caregivers** helping a parent or grandparent check a
  message before money or personal information changes hands.

The interface is deliberately simple: one paste box, one button, and
large-text-friendly results.

## Privacy: fully offline, local-first

- **Zero network permission requests.** The Android manifest declares no
  permissions at all — not even `INTERNET`. (The Flutter debug/profile
  manifests include `INTERNET` solely because the Flutter dev tooling needs it
  for hot reload; it is absent from release builds.)
- **Zero telemetry.** No analytics, no crash reporting, no third-party SDKs.
- **All data stays on the device.** The text you paste is never transmitted,
  logged, or stored beyond the current screen. The pattern database is a JSON
  file bundled inside the app.

## How matching works

The engine lives in `lib/engine/` and is **pure Dart** — no Flutter imports —
so it can be unit-tested without widgets:

- **`PatternDatabase`** (`lib/engine/pattern_database.dart`) loads the bundled
  `assets/patterns.json`. Each pattern has an id, name, category, plain-language
  explanation, advice, and a list of weighted signals.
- **`Matcher`** (`lib/engine/matcher.dart`) scores the input text against every
  pattern. A signal is a case-insensitive regex or keyword rule with a weight
  (e.g. urgency language, demands for gift cards or wire transfers, secrecy
  demands). A pattern's score is the sum of its fired signal weights, clamped
  to `[0, 1]`. Patterns scoring below a small threshold are dropped; results
  are sorted highest score first.
- Each match returns: `pattern_id`, `name`, `category`, `score`,
  `matched_signals`, `explanation`, and `advice`.
- The UI color-codes severity from the score: **high** (≥ 0.6, red),
  **medium** (≥ 0.35, orange), **low** (yellow).

The bundled database covers 12 scam families: romance scam, IRS/tax
impersonation, grandparent scam, lottery/sweepstakes, phishing credential
harvest, tech support scam, crypto investment scam, package delivery phishing,
bank fraud alert scam, charity scam, rental scam, and sextortion.

## Honest limits

ScamShield's patterns are **heuristics, not proof**:

- A match is a **warning sign**, not a verdict. Legitimate messages can
  occasionally trip a pattern.
- **No match does not mean a message is safe.** Scammers constantly reword
  their scripts, and this database cannot know every variation.
- Weights are hand-tuned judgment calls, not statistical confidence scores.

When in doubt: stop, don't click or pay, and ask someone you trust. In the US,
scams can be reported to the FTC at reportfraud.ftc.gov and to the FBI at
ic3.gov.

## Building and testing

Requires the Flutter SDK (3.x, Dart 3.x).

```sh
flutter pub get
flutter test        # engine unit tests (matcher scoring, ranking, clean input)
flutter analyze     # static analysis
flutter run         # launch on a connected device or emulator
```

## Contributing new patterns

The pattern database is `assets/patterns.json` — no Dart code changes needed
to add or tune a pattern.

Each pattern looks like:

```json
{
  "id": "my-new-scam",
  "name": "Human-Readable Name",
  "category": "Category shown in results",
  "explanation": "What this scam is, in plain language.",
  "advice": "Concrete, calm steps the reader should take.",
  "signals": [
    { "label": "What this detects", "type": "regex", "pattern": "case-insensitive regex", "weight": 0.35 },
    { "label": "Another indicator", "type": "keyword", "pattern": "gift card", "weight": 0.3 }
  ]
}
```

Guidelines for a good contribution:

1. **Signals are real indicators**, not vibes: urgency language, payment-method
   demands (gift cards, wire, crypto), secrecy demands, impersonation claims,
   threats, deadlines.
2. **Weights should sum to roughly 1.0** across a pattern's signals, so a
   message hitting most signals scores high while a single weak hit stays low.
3. **Write explanation and advice for a non-technical reader** — short
   sentences, no jargon, calm tone.
4. **Use only synthetic examples.** Never include real phone numbers, names,
   addresses, or copied scam texts from real victims in patterns, tests, or
   docs — fictional placeholders only.
5. **Add a test** in `test/matcher_test.dart` showing a synthetic sample
   message matching your new pattern.

Pull requests welcome. The project is Apache-2.0 licensed.

## License

Apache-2.0 — see [LICENSE](LICENSE). Copyright synth (synthalorian).

---


Part of [Blackshield Company](https://github.com/Blackshield-Company).
