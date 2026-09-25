import 'package:flutter/material.dart';
import 'package:mind_deck/data/models/test_question_model.dart';

class MatchingBody extends StatefulWidget {
  final TestQuestionModel question;
  final Map<String, String>? currentMatches;
  final bool isChecked;
  final ValueChanged<Map<String, String>> onMatchesChanged;

  const MatchingBody({
    super.key,
    required this.question,
    required this.currentMatches,
    required this.isChecked,
    required this.onMatchesChanged,
  });

  @override
  State<MatchingBody> createState() => _MatchingBodyState();
}

class _MatchingBodyState extends State<MatchingBody> {
  late List<dynamic> _leftList;
  late List<dynamic> _rightList;

  String? _selectedLeftId;
  String? _selectedRightId;

  @override
  void initState() {
    super.initState();
    _leftList = List.from(widget.question.leftColumn)..shuffle();
    _rightList = List.from(widget.question.rightColumn)..shuffle();
  }

  void _onLeftSelected(String id) {
    if (widget.isChecked) return;

    final updatedMatches = Map<String, String>.from(
      widget.currentMatches ?? {},
    );
    if (updatedMatches.containsKey(id) &&
        _selectedLeftId == null &&
        _selectedRightId == null) {
      updatedMatches.remove(id);
      widget.onMatchesChanged(updatedMatches);
      setState(() {
        _selectedLeftId = id;
      });
      return;
    }

    setState(() {
      _selectedLeftId = (_selectedLeftId == id) ? null : id;
      _checkMatch();
    });
  }

  void _onRightSelected(String id) {
    if (widget.isChecked) return;

    final updatedMatches = Map<String, String>.from(
      widget.currentMatches ?? {},
    );
    if (updatedMatches.containsValue(id) &&
        _selectedLeftId == null &&
        _selectedRightId == null) {
      updatedMatches.removeWhere((k, v) => v == id);
      widget.onMatchesChanged(updatedMatches);
      setState(() {
        _selectedRightId = id;
      });
      return;
    }

    setState(() {
      _selectedRightId = (_selectedRightId == id) ? null : id;
      _checkMatch();
    });
  }

  void _checkMatch() {
    if (_selectedLeftId != null && _selectedRightId != null) {
      final updatedMatches = Map<String, String>.from(
        widget.currentMatches ?? {},
      );

      // Remove any existing matches for these ids to prevent duplicate links
      updatedMatches.removeWhere(
        (key, val) => key == _selectedLeftId || val == _selectedRightId,
      );

      updatedMatches[_selectedLeftId!] = _selectedRightId!;
      widget.onMatchesChanged(updatedMatches);

      _selectedLeftId = null;
      _selectedRightId = null;
    }
  }

  final List<Color> _matchColors = [
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.brown,
    Colors.cyan,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final matches = widget.currentMatches ?? {};
    final matchesList = matches.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GHÉP CẶP TƯƠNG ỨNG',
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column
            Expanded(
              child: Column(
                children: _leftList.map((item) {
                  final String id = item['id']?.toString() ?? '';
                  final String text = item['text']?.toString() ?? '';

                  final isMatched = matches.containsKey(id);
                  final isSelected = _selectedLeftId == id;

                  Color? pairColor;
                  if (isMatched && !widget.isChecked) {
                    int matchIndex = matchesList.indexOf(id);
                    if (matchIndex != -1) {
                      pairColor =
                          _matchColors[matchIndex % _matchColors.length];
                    }
                  }

                  Color borderColor = colorScheme.outline.withValues(alpha: 0.6);
                  Color bgColor = colorScheme.surface;
                  Color textColor = colorScheme.onSurface;
                  double borderWidth = 1.5;

                  if (widget.isChecked) {
                    final matchedRightId = matches[id] ?? '';
                    final isCorrect = id == matchedRightId;
                    borderColor = isCorrect
                        ? Colors.green.shade600
                        : colorScheme.error;
                    bgColor = isCorrect
                        ? Colors.green.shade50
                        : colorScheme.errorContainer.withValues(alpha: 0.2);
                    textColor = isCorrect
                        ? Colors.green.shade900
                        : colorScheme.error;
                    borderWidth = 2.0;
                  } else if (isSelected) {
                    borderColor = colorScheme.primary;
                    bgColor = colorScheme.primaryContainer.withValues(
                      alpha: 0.15,
                    );
                    textColor = colorScheme.primary;
                    borderWidth = 2.0;
                  } else if (isMatched && pairColor != null) {
                    borderColor = pairColor.withValues(alpha: 0.7);
                    bgColor = pairColor.withValues(alpha: 0.1);
                    textColor = pairColor;
                    borderWidth = 2.0;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: () => _onLeftSelected(id),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 72),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: borderColor,
                            width: borderWidth,
                          ),
                        ),
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            fontWeight:
                                isSelected || isMatched || widget.isChecked
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(width: 16),
            // Right Column
            Expanded(
              child: Column(
                children: _rightList.map((item) {
                  final String id = item['id']?.toString() ?? '';
                  final String text = item['text']?.toString() ?? '';

                  final isMatched = matches.containsValue(id);
                  final isSelected = _selectedRightId == id;

                  String matchedLeftId = '';
                  Color? pairColor;

                  if (isMatched) {
                    matchedLeftId = matches.entries
                        .firstWhere((e) => e.value == id)
                        .key;
                    if (!widget.isChecked) {
                      int matchIndex = matchesList.indexOf(matchedLeftId);
                      if (matchIndex != -1) {
                        pairColor =
                            _matchColors[matchIndex % _matchColors.length];
                      }
                    }
                  }

                  Color borderColor = colorScheme.outline.withValues(alpha: 0.6);
                  Color bgColor = colorScheme.surface;
                  Color textColor = colorScheme.onSurface;
                  double borderWidth = 1.5;

                  if (widget.isChecked) {
                    final matchedRightId = matches[id] ?? '';
                    final isCorrect = id == matchedRightId;
                    borderColor = isCorrect
                        ? Colors.green.shade600
                        : colorScheme.error;
                    bgColor = isCorrect
                        ? Colors.green.shade50
                        : colorScheme.errorContainer.withValues(alpha: 0.2);
                    textColor = isCorrect
                        ? Colors.green.shade900
                        : colorScheme.error;
                    borderWidth = 2.0;
                  } else if (isSelected) {
                    borderColor = colorScheme.primary;
                    bgColor = colorScheme.primaryContainer.withValues(
                      alpha: 0.15,
                    );
                    textColor = colorScheme.primary;
                    borderWidth = 2.0;
                  } else if (isMatched && pairColor != null) {
                    borderColor = pairColor.withValues(alpha: 0.7);
                    bgColor = pairColor.withValues(alpha: 0.1);
                    textColor = pairColor;
                    borderWidth = 2.0;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: InkWell(
                      onTap: () => _onRightSelected(id),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 72),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: borderColor,
                            width: borderWidth,
                          ),
                        ),
                        child: Text(
                          text,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            fontWeight:
                                isSelected || isMatched || widget.isChecked
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
