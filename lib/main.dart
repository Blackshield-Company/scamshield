import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'engine/engine.dart';

void main() {
  runApp(const ScamShieldApp());
}

class ScamShieldApp extends StatelessWidget {
  const ScamShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ScamShield',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        // Large-text friendly defaults for older users.
        textTheme: Typography.blackMountainView.apply(fontSizeFactor: 1.15),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  Matcher? _matcher;
  List<MatchResult>? _results;
  bool _analyzed = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadDatabase();
  }

  Future<void> _loadDatabase() async {
    try {
      final json = await rootBundle.loadString('assets/patterns.json');
      setState(() {
        _matcher = Matcher(PatternDatabase.fromJsonString(json));
      });
    } catch (e) {
      setState(() => _loadError = 'Could not load pattern database: $e');
    }
  }

  void _analyze() {
    final matcher = _matcher;
    if (matcher == null) return;
    setState(() {
      _results = matcher.analyze(_controller.text);
      _analyzed = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ScamShield'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Paste the suspicious message below — a text, email, or what a caller said. Everything is checked on this device; nothing is sent anywhere.',
              style: TextStyle(fontSize: 17),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 8,
              minLines: 4,
              style: const TextStyle(fontSize: 17),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Suspicious message',
                hintText: 'Paste the message here…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _matcher == null ? null : _analyze,
              icon: const Icon(Icons.shield_outlined),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Analyze', style: TextStyle(fontSize: 20)),
              ),
            ),
            if (_loadError != null) ...[
              const SizedBox(height: 16),
              Text(_loadError!, style: const TextStyle(color: Colors.red)),
            ],
            if (_analyzed) ...[
              const SizedBox(height: 24),
              _buildResults(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final results = _results ?? const <MatchResult>[];
    if (_controller.text.trim().isEmpty) {
      return const Text(
        'Paste a message first, then tap Analyze.',
        style: TextStyle(fontSize: 17),
      );
    }
    if (results.isEmpty) {
      return Card(
        color: Colors.green.shade50,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No known scam patterns detected. This is not proof the message is safe — when in doubt, ask someone you trust before responding, clicking, or paying.',
            style: TextStyle(fontSize: 17),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${results.length} pattern${results.length == 1 ? '' : 's'} detected',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...results.map((r) => _MatchCard(result: r)),
        const SizedBox(height: 8),
        const Text(
          'ScamShield uses simple pattern heuristics. A match is a warning sign, not proof of a scam — and no match is not proof of safety.',
          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.result});

  final MatchResult result;

  Color _severityColor() {
    switch (result.severity) {
      case Severity.high:
        return Colors.red.shade700;
      case Severity.medium:
        return Colors.orange.shade800;
      case Severity.low:
        return Colors.amber.shade800;
    }
  }

  String _severityLabel() {
    switch (result.severity) {
      case Severity.high:
        return 'HIGH RISK';
      case Severity.medium:
        return 'MEDIUM RISK';
      case Severity.low:
        return 'LOW RISK';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _severityColor();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(Icons.warning_amber_rounded, color: color, size: 32),
        title: Text(
          result.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_severityLabel()} — score ${(result.score * 100).round()}%',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Section(
            heading: 'What triggered this',
            body: result.matchedSignals.map((s) => '• $s').join('\n'),
          ),
          _Section(heading: 'What this scam is', body: result.explanation),
          _Section(heading: 'What to do', body: result.advice),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.heading, required this.body});

  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}
