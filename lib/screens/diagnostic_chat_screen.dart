import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/diagnostic_models.dart';
import '../services/diagnostic_service.dart';
import '../widgets/app_page.dart';

/// The interactive AI diagnostic chat screen.
///
/// Flow:
///   1. Receives image + description from the caller.
///   2. Calls /api/diagnostic/start → AI identifies product + asks questions.
///   3. User answers questions in a form-style chat.
///   4. Calls /api/diagnostic/continue with answers.
///   5. Repeat until is_complete=true.
///   6. Shows final recommendation inline and navigates to the appropriate
///      result screen.
class DiagnosticChatScreen extends StatefulWidget {
  const DiagnosticChatScreen({
    required this.imageBytes,
    required this.initialDescription,
    required this.mode,
    this.service,
    super.key,
  });

  final Uint8List imageBytes;
  final String initialDescription;

  /// 'quick_scan' shows the 4R recommendation result.
  /// 'reduce' shows the repair assessment result.
  final String mode;

  final DiagnosticService? service;

  @override
  State<DiagnosticChatScreen> createState() => _DiagnosticChatScreenState();
}

class _DiagnosticChatScreenState extends State<DiagnosticChatScreen> {
  late final DiagnosticService _service;

  // Chat state
  final List<DiagnosticMessage> _messages = [];
  final List<TextEditingController> _answerControllers = [];

  String? _sessionId;
  List<String> _currentQuestions = [];
  bool _isLoading = false;
  bool _isComplete = false;
  DiagnosticFinalRecommendation? _finalRecommendation;
  String? _identifiedProduct;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? DiagnosticService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  @override
  void dispose() {
    for (final c in _answerControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _startSession() async {
    setState(() {
      _isLoading = true;
      _messages.add(
        const DiagnosticMessage(
          role: 'ai',
          text: '',
          isLoading: true,
        ),
      );
    });

    try {
      final response = await _service.startDiagnostic(
        imageBytes: widget.imageBytes,
        description: widget.initialDescription,
      );

      if (!mounted) return;

      _sessionId = response.sessionId;
      _identifiedProduct = response.identifiedProduct;

      // Replace loading bubble with identification message
      final identText =
          '**I can identify this as: ${response.identifiedProduct}**\n\n'
          '${response.identifiedCondition.isNotEmpty ? '_Condition: ${response.identifiedCondition}_\n\n' : ''}'
          '${response.aiObservation}';

      setState(() {
        _messages.removeLast(); // remove loading bubble
        _messages.add(DiagnosticMessage(role: 'ai', text: identText));

        if (response.isComplete && response.finalRecommendation != null) {
          _isComplete = true;
          _finalRecommendation = response.finalRecommendation;
          _messages.add(
            DiagnosticMessage(
              role: 'ai',
              text: _buildFinalText(response.finalRecommendation!),
            ),
          );
        } else if (response.followUpQuestions.isNotEmpty) {
          _currentQuestions = response.followUpQuestions;
          _answerControllers.clear();
          for (int i = 0; i < _currentQuestions.length; i++) {
            _answerControllers.add(TextEditingController());
          }
          _messages.add(
            DiagnosticMessage(
              role: 'ai',
              text: 'To give you a more accurate assessment, I have a few questions:',
              questions: response.followUpQuestions,
            ),
          );
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _messages.add(
          DiagnosticMessage(
            role: 'ai',
            text: 'I was unable to analyze your item right now. '
                'Please check your connection and try again.',
          ),
        );
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAnswers() async {
    // Validate: all questions must be answered
    final answers =
        _answerControllers.map((c) => c.text.trim()).toList();
    if (answers.any((a) => a.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions before continuing.'),
        ),
      );
      return;
    }

    // Add user answers to chat
    final userText = _currentQuestions
        .asMap()
        .entries
        .map((e) => '**Q: ${e.value}**\nA: ${answers[e.key]}')
        .join('\n\n');

    setState(() {
      _messages.add(DiagnosticMessage(role: 'user', text: userText));
      _isLoading = true;
      _messages.add(
        const DiagnosticMessage(role: 'ai', text: '', isLoading: true),
      );
      _currentQuestions = [];
    });

    // Clear answer controllers
    for (final c in _answerControllers) {
      c.dispose();
    }
    _answerControllers.clear();

    try {
      final response = await _service.continueDiagnostic(
        sessionId: _sessionId!,
        answers: answers,
      );

      if (!mounted) return;

      setState(() {
        _messages.removeLast(); // remove loading bubble
        _isLoading = false;

        if (response.summary.isNotEmpty) {
          _messages.add(
            DiagnosticMessage(role: 'ai', text: response.summary),
          );
        }

        if (response.isComplete && response.finalRecommendation != null) {
          _isComplete = true;
          _finalRecommendation = response.finalRecommendation;
          _messages.add(
            DiagnosticMessage(
              role: 'ai',
              text: _buildFinalText(response.finalRecommendation!),
            ),
          );
        } else if (response.followUpQuestions.isNotEmpty) {
          _currentQuestions = response.followUpQuestions;
          for (int i = 0; i < _currentQuestions.length; i++) {
            _answerControllers.add(TextEditingController());
          }
          _messages.add(
            DiagnosticMessage(
              role: 'ai',
              text: 'A few more questions to refine my assessment:',
              questions: response.followUpQuestions,
            ),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.removeLast();
        _isLoading = false;
        _messages.add(
          DiagnosticMessage(
            role: 'ai',
            text: 'Something went wrong processing your answers. Please try again.',
          ),
        );
      });
    }
  }

  String _buildFinalText(DiagnosticFinalRecommendation rec) {
    return '**Diagnosis complete.**\n\n'
        '🔧 **Repairability:** ${rec.repairability} (${rec.repairabilityScore}/100)\n\n'
        '🔍 **Possible issue:** ${rec.possibleIssue}\n\n'
        '${rec.repairAreas.isNotEmpty ? '🛠 **Areas to inspect:** ${rec.repairAreas.join(', ')}\n\n' : ''}'
        '${rec.repairExplanation}\n\n'
        '♻️ **Recommended path:** ${rec.recommended4r}\n\n'
        '**Next step:** ${rec.recommendedAction}\n\n'
        '_${rec.wasteImpact}_';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Diagnostic'),
            if (_identifiedProduct != null)
              Text(
                _identifiedProduct!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          if (_isComplete)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Complete',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: AppPage(
        child: Column(
          children: [
            // ── Item image strip ──────────────────────────────────────────
            Container(
              height: 120,
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: theme.colorScheme.surfaceContainerHighest,
              ),
              child: Image.memory(
                widget.imageBytes,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            const SizedBox(height: 8),
            // ── Chat messages ─────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  return message.isAi
                      ? _AiBubble(
                          message: message,
                          answerControllers:
                              index == _messages.length - 1 &&
                                      message.questions.isNotEmpty
                                  ? _answerControllers
                                  : const [],
                          onSubmit: _currentQuestions.isNotEmpty && !_isLoading
                              ? _submitAnswers
                              : null,
                        )
                      : _UserBubble(message: message);
                },
              ),
            ),
            // ── Final action buttons ──────────────────────────────────────
            if (_isComplete) _buildFinalActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: () => _navigateToResult(context),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('See Full Report'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () =>
                Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  void _navigateToResult(BuildContext context) {
    if (_finalRecommendation == null) return;

    if (widget.mode == 'reduce') {
      // Navigate to ReduceResultScreen with the data we have
      // We synthesise a RepairAnalysisResult from the diagnostic result.
      _navigateReduceResult(context);
    } else {
      // quick_scan mode → navigate to RecommendationScreen
      _navigateRecommendationResult(context);
    }
  }

  void _navigateReduceResult(BuildContext context) {
    final rec = _finalRecommendation!;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DiagnosticRepairResultScreen(
          imageBytes: widget.imageBytes,
          product: _identifiedProduct ?? 'Your item',
          recommendation: rec,
        ),
      ),
    );
  }

  void _navigateRecommendationResult(BuildContext context) {
    final rec = _finalRecommendation!;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DiagnosticRecommendationScreen(
          product: _identifiedProduct ?? 'Your item',
          imageBytes: widget.imageBytes,
          recommendation: rec,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Chat bubbles
// ---------------------------------------------------------------------------

class _AiBubble extends StatelessWidget {
  const _AiBubble({
    required this.message,
    required this.answerControllers,
    this.onSubmit,
  });

  final DiagnosticMessage message;
  final List<TextEditingController> answerControllers;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.auto_awesome,
              size: 16,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: message.isLoading
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Thinking...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        )
                      : _MarkdownText(text: message.text),
                ),
                // Follow-up questions form
                if (message.questions.isNotEmpty && answerControllers.length == message.questions.length) ...[
                  const SizedBox(height: 12),
                  ...message.questions.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.key + 1}. ${entry.value}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: answerControllers[entry.key],
                            minLines: 1,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Your answer...',
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (onSubmit != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onSubmit,
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Submit Answers'),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message});

  final DiagnosticMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: _MarkdownText(
                text: message.text,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primary,
            child: Icon(
              Icons.person,
              size: 16,
              color: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple bold/italic text renderer using RichText (no markdown package needed).
class _MarkdownText extends StatelessWidget {
  const _MarkdownText({required this.text, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyMedium?.copyWith(
          color: color,
          height: 1.45,
        ) ??
        TextStyle(color: color, height: 1.45);

    final spans = _parse(text, baseStyle);
    return RichText(text: TextSpan(children: spans));
  }

  List<InlineSpan> _parse(String text, TextStyle base) {
    final spans = <InlineSpan>[];
    // Process line by line, handling **bold**, _italic_, and plain text.
    final lines = text.split('\n');
    for (int li = 0; li < lines.length; li++) {
      if (li > 0) spans.add(const TextSpan(text: '\n'));
      final line = lines[li];
      _parseInline(line, base, spans);
    }
    return spans;
  }

  void _parseInline(String line, TextStyle base, List<InlineSpan> out) {
    final pattern = RegExp(r'\*\*(.+?)\*\*|_(.+?)_|([^\*_]+)');
    for (final match in pattern.allMatches(line)) {
      if (match.group(1) != null) {
        out.add(TextSpan(
          text: match.group(1),
          style: base.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(2) != null) {
        out.add(TextSpan(
          text: match.group(2),
          style: base.copyWith(fontStyle: FontStyle.italic),
        ));
      } else {
        out.add(TextSpan(text: match.group(3), style: base));
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Result screens built from diagnostic data
// ---------------------------------------------------------------------------

/// Shown at the end of a quick_scan diagnostic.
class DiagnosticRecommendationScreen extends StatelessWidget {
  const DiagnosticRecommendationScreen({
    required this.product,
    required this.imageBytes,
    required this.recommendation,
    super.key,
  });

  final String product;
  final Uint8List imageBytes;
  final DiagnosticFinalRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rec = recommendation;
    final scoreColor = rec.repairabilityScore >= 70
        ? Colors.green
        : rec.repairabilityScore >= 40
            ? Colors.orange
            : Colors.red;

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostic Recommendation')),
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.memory(imageBytes, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              product,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            // Score card
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 64,
                          height: 64,
                          child: CircularProgressIndicator(
                            value: rec.repairabilityScore / 100,
                            strokeWidth: 7,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                          ),
                        ),
                        Text(
                          '${rec.repairabilityScore}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rec.repairability,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Repairability Score',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        rec.recommended4r.toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      icon: Icons.search,
                      label: 'Possible Issue',
                    ),
                    const SizedBox(height: 8),
                    Text(rec.possibleIssue),
                    if (rec.repairAreas.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _SectionTitle(icon: Icons.build, label: 'Areas to Inspect'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: rec.repairAreas
                            .map((a) => Chip(label: Text(a)))
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _SectionTitle(
                      icon: Icons.lightbulb_outline,
                      label: 'Assessment',
                    ),
                    const SizedBox(height: 8),
                    Text(rec.repairExplanation, style: const TextStyle(height: 1.45)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.eco, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rec.wasteImpact,
                        style: TextStyle(
                          color: Colors.green.shade800,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      icon: Icons.arrow_forward_ios,
                      label: 'Recommended Next Step',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      rec.recommendedAction,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown at the end of a reduce/repair diagnostic.
class DiagnosticRepairResultScreen extends StatelessWidget {
  const DiagnosticRepairResultScreen({
    required this.imageBytes,
    required this.product,
    required this.recommendation,
    super.key,
  });

  final Uint8List imageBytes;
  final String product;
  final DiagnosticFinalRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rec = recommendation;

    return Scaffold(
      appBar: AppBar(title: const Text('Repair Assessment')),
      body: AppPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.memory(imageBytes, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    product,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    rec.repairability,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      icon: Icons.verified_outlined,
                      label: 'Repairability Evaluation',
                    ),
                    const SizedBox(height: 8),
                    Text(rec.repairExplanation, style: const TextStyle(height: 1.45)),
                    const Divider(height: 20),
                    _SectionTitle(
                      icon: Icons.search,
                      label: 'Possible Issue',
                    ),
                    const SizedBox(height: 8),
                    Text(rec.possibleIssue),
                  ],
                ),
              ),
            ),
            if (rec.repairAreas.isNotEmpty) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionTitle(
                        icon: Icons.tune_outlined,
                        label: 'Possible Repair Areas',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Potential components to inspect (not confirmed faults):',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: rec.repairAreas
                            .map(
                              (area) => Chip(
                                avatar: const Icon(Icons.tune_outlined, size: 16),
                                label: Text(area),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.eco, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Environmental Impact',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      rec.wasteImpact,
                      style: TextStyle(color: Colors.green.shade800, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(
                      icon: Icons.arrow_circle_right_outlined,
                      label: 'Recommended Action',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      rec.recommendedAction,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
