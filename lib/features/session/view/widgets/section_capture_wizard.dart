import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/di.dart';
import '../../../../data/models/session.dart';
import '../../controllers/session_controller.dart';
import '../../domain/session_models.dart';
import '../../ocr/party_ocr_analyzer.dart';
import '../../../shared/services/image_normalizer.dart';
import '../session_scope.dart';

typedef PartyOcrReviewPresenter = Future<PartyOcrReviewDecision?> Function(
  BuildContext context,
  PartyOcrAnalysis analysis,
  Map<PartyField, TextEditingController> controllers,
  double confidence,
  bool imageWasPreprocessed,
  Map<PartyField, String> previousValues,
  Map<PartyField, PartyOcrFieldSuggestion?> initialSuggestions,
  double sharpness,
);

class PartyOcrWizardResult {
  const PartyOcrWizardResult({
    required this.appliedValues,
    required this.previousValues,
    required this.previousMirrorsRequested,
  });

  final Map<PartyField, String> appliedValues;
  final Map<PartyField, String> previousValues;
  final bool previousMirrorsRequested;
}

class SectionCaptureWizard {
  SectionCaptureWizard(
    this.ref,
    this.formType, {
    PartyOcrAnalyzer? analyzer,
    this.presenter,
  }) : _analyzer = analyzer ?? const PartyOcrAnalyzer();

  static const double _kSharpnessThreshold = 55;
  static const double _kLowConfidenceThreshold = 0.62;

  final WidgetRef ref;
  final FormType formType;
  final ImagePicker _picker = ImagePicker();
  final PartyOcrAnalyzer _analyzer;
  final PartyOcrReviewPresenter? presenter;

  Future<PartyOcrWizardResult?> captureSection({
    required BuildContext context,
    required PartyRole role,
  }) async {
    final file = await _selectImage(context);
    if (file == null) return null;
    if (!context.mounted) return null;
    return processImage(context: context, role: role, image: file);
  }

  Future<bool> _confirmLowConfidence(
    BuildContext context,
    double confidence,
    double sharpness,
  ) async {
    final percent = (confidence * 100).clamp(0, 100).toStringAsFixed(1);
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Low confidence result'),
            content: Text(
              'The scan confidence is $percent%. You can retake the photo or apply the current suggestions.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Retake'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Apply'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @visibleForTesting
  Future<PartyOcrWizardResult?> processImage({
    required BuildContext context,
    required PartyRole role,
    required File image,
  }) async {
    final snapshot = _snapshot(role);

    try {
      final normalizer = ref.read(imageNormalizerProvider);
      final improveLegibility = ref.read(legibilityPreferenceProvider);
      final normalized = await normalizer.normalize(
        image,
        improveLegibility: improveLegibility,
        cropPreset: ImageCropPreset.profileCard,
      );

      if (normalized.sharpness < _kSharpnessThreshold) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Image is blurry. Hold steady and try again.'),
              ),
            );
        }
        return null;
      }

      final ocrService = ref.read(ocrServiceProvider);
      final result = await ocrService.analyze(normalized.file, hints: {
        'targetField': 'partySection',
        'preprocessed': normalized.legibilityApplied,
      });

      if (result.confidence < _kLowConfidenceThreshold && context.mounted) {
        final proceed = await _confirmLowConfidence(
          context,
          result.confidence,
          normalized.sharpness,
        );
        if (!proceed) {
          return null;
        }
      }

      final analysis = _analyzer.analyze(result.fields);
      final controllers = _buildControllers(analysis, snapshot.values);
      final initialSelections = {
        for (final field in PartyField.values)
          field: analysis.primarySuggestionFor(field),
      };

      final diagnostics = ref.read(diagnosticsRecorderProvider);
      final diagnosticsMetadata = {
        'role': role.name,
        'formType': formType.name,
        'confidence': result.confidence,
        'sharpness': normalized.sharpness,
        'brightness': normalized.brightness,
      };

      try {
        final review = presenter ?? _presentReviewDialog;
        if (!context.mounted) return null;
        final decision = await review(
          context,
          analysis,
          controllers,
          result.confidence,
          normalized.legibilityApplied,
          snapshot.values,
          initialSelections,
          normalized.sharpness,
        );

        if (!context.mounted) return null;

        if (decision == null || !decision.applied) {
          return null;
        }

        final payload = <PartyField, String>{
          for (final entry in decision.values.entries)
            entry.key: entry.value.trim(),
        };

        final hasContent = payload.values.any((value) => value.isNotEmpty);
        if (!hasContent) {
          return null;
        }

        final notifier = ref.read(sessionControllerProvider(formType).notifier);
        notifier.setMirrorFromRequested(role, false);
        notifier.applyPartyFields(role, payload);

        if (decision.sentToDiagnostics ?? false) {
          final metadata = {
            ...diagnosticsMetadata,
            'appliedValues': payload,
            'previousValues': snapshot.values,
          };
          await diagnostics.capture(
            image: normalized.file,
            metadata: metadata,
            ocrFields: result.fields,
          );
        }

        return PartyOcrWizardResult(
          appliedValues: payload,
          previousValues: snapshot.values,
          previousMirrorsRequested: snapshot.mirrorsRequested,
        );
      } finally {
        for (final controller in controllers.values) {
          controller.dispose();
        }
      }
    } catch (error, stackTrace) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Section OCR failed: $error')),
        );
      }
      ref.read(appLoggerProvider).error(
            'Section OCR failed',
            error: error,
            stackTrace: stackTrace,
          );
      return null;
    }
  }

  Future<File?> _selectImage(BuildContext context) async {
    final root = ProviderScope.containerOf(context, listen: false);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (bottomSheetContext) => SessionScope(
        container: root,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(title: Text('Capture Party Section')),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () =>
                    Navigator.of(bottomSheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () =>
                    Navigator.of(bottomSheetContext).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
    if (!context.mounted || source == null) return null;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 100,
      preferredCameraDevice: CameraDevice.rear,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  _PartySnapshot _snapshot(PartyRole role) {
    final state = ref.read(sessionControllerProvider(formType));
    final member = state.party.members[role];
    if (member == null) {
      return const _PartySnapshot(
        mirrorsRequested: false,
        values: {
          PartyField.name: '',
          PartyField.department: '',
          PartyField.email: '',
        },
      );
    }

    final values = <PartyField, String>{
      for (final field in PartyField.values)
        field: member.fields[field]?.value ?? '',
    };
    return _PartySnapshot(
      mirrorsRequested: member.mirrorsRequested,
      values: values,
    );
  }

  Map<PartyField, TextEditingController> _buildControllers(
    PartyOcrAnalysis analysis,
    Map<PartyField, String> previousValues,
  ) {
    final controllers = <PartyField, TextEditingController>{};
    for (final field in PartyField.values) {
      final suggestion = analysis.primarySuggestionFor(field)?.value ?? '';
      final existing = previousValues[field] ?? '';
      final initial = suggestion.isNotEmpty ? suggestion : existing;
      controllers[field] = TextEditingController(text: initial);
    }
    return controllers;
  }
}

Future<PartyOcrReviewDecision?> _presentReviewDialog(
  BuildContext context,
  PartyOcrAnalysis analysis,
  Map<PartyField, TextEditingController> controllers,
  double confidence,
  bool imageWasPreprocessed,
  Map<PartyField, String> previousValues,
  Map<PartyField, PartyOcrFieldSuggestion?> initialSelections,
  double sharpness,
) {
  final root = ProviderScope.containerOf(context, listen: false);
  return showDialog<PartyOcrReviewDecision>(
    context: context,
    builder: (dialogContext) => SessionScope(
      container: root,
      child: _PartyOcrReviewDialog(
        analysis: analysis,
        controllers: controllers,
        initialSelections: initialSelections,
        confidence: confidence,
        imageWasPreprocessed: imageWasPreprocessed,
        previousValues: previousValues,
        sharpness: sharpness,
      ),
    ),
  );
}

class _PartySnapshot {
  const _PartySnapshot({
    required this.mirrorsRequested,
    required this.values,
  });

  final bool mirrorsRequested;
  final Map<PartyField, String> values;
}

class PartyOcrReviewDecision {
  const PartyOcrReviewDecision({
    required this.applied,
    required this.values,
    this.sentToDiagnostics,
  });

  final bool applied;
  final Map<PartyField, String> values;
  final bool? sentToDiagnostics;
}

class _PartyOcrReviewDialog extends StatefulWidget {
  const _PartyOcrReviewDialog({
    required this.analysis,
    required this.controllers,
    required this.initialSelections,
    required this.confidence,
    required this.imageWasPreprocessed,
    required this.previousValues,
    required this.sharpness,
  });

  final PartyOcrAnalysis analysis;
  final Map<PartyField, TextEditingController> controllers;
  final Map<PartyField, PartyOcrFieldSuggestion?> initialSelections;
  final double confidence;
  final bool imageWasPreprocessed;
  final Map<PartyField, String> previousValues;
  final double sharpness;

  @override
  State<_PartyOcrReviewDialog> createState() => _PartyOcrReviewDialogState();
}

class _PartyOcrReviewDialogState extends State<_PartyOcrReviewDialog> {
  late final Map<PartyField, PartyOcrFieldSuggestion?> _selection;
  bool _sentToDiagnostics = false;

  @override
  void initState() {
    super.initState();
    _selection = Map<PartyField, PartyOcrFieldSuggestion?>.from(
        widget.initialSelections);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidence = (widget.confidence * 100).clamp(0, 100);
    final sharpness = widget.sharpness;

    return AlertDialog(
      title: const Text('Map OCR Results'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.speed, size: 16),
                    label: Text('${confidence.toStringAsFixed(1)}% confidence'),
                  ),
                  Chip(
                    avatar: const Icon(Icons.blur_circular, size: 16),
                    label: Text('Sharpness ${sharpness.toStringAsFixed(0)}'),
                  ),
                  if (widget.imageWasPreprocessed)
                    const Chip(
                      avatar: Icon(Icons.insights_outlined, size: 16),
                      label: Text('Legibility boost'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              for (final field in PartyField.values) ...[
                _buildFieldSection(context, field),
                if (field != PartyField.values.last) const SizedBox(height: 20),
              ],
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text('OCR Evidence'),
                subtitle: const Text('Show extracted lines'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.analysis.lines.join('\n'),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(
            const PartyOcrReviewDecision(applied: false, values: {}),
          ),
          child: const Text('Cancel'),
        ),
        if (!_sentToDiagnostics)
          TextButton.icon(
            onPressed: () {
              setState(() => _sentToDiagnostics = true);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Capture marked for diagnostics.'),
                  ),
                );
            },
            icon: const Icon(Icons.bug_report, size: 16),
            label: const Text('Send to Diagnostics'),
          ),
        TextButton.icon(
          onPressed: _resetToOriginal,
          icon: const Icon(Icons.undo, size: 16),
          label: const Text('Undo edits'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(
              PartyOcrReviewDecision(
                applied: true,
                values: {
                  for (final field in PartyField.values)
                    field: widget.controllers[field]!.text,
                },
                sentToDiagnostics: _sentToDiagnostics,
              ),
            );
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildFieldSection(BuildContext context, PartyField field) {
    final theme = Theme.of(context);
    final suggestions = widget.analysis.suggestionsFor(field);
    final controller = widget.controllers[field]!;
    final selected = _selection[field];
    final color = selected != null
        ? _confidenceColor(selected.confidence)
        : theme.dividerColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(field.label, style: theme.textTheme.titleSmall),
            const SizedBox(width: 8),
            if (selected != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _confidenceLabel(selected.confidence),
                  style: theme.textTheme.labelSmall?.copyWith(color: color),
                ),
              ),
          ],
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map(
                  (suggestion) => ChoiceChip(
                    label: Text(
                      suggestion.value,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: identical(selected, suggestion),
                    selectedColor: _confidenceColor(suggestion.confidence)
                        .withValues(alpha: 0.18),
                    labelStyle: theme.textTheme.bodySmall?.copyWith(
                      color: identical(selected, suggestion)
                          ? _confidenceColor(suggestion.confidence)
                          : null,
                    ),
                    onSelected: (_) => _selectSuggestion(field, suggestion),
                  ),
                )
                .toList(growable: false),
          ),
        ],
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: color, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: color.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
          ),
          onChanged: (value) {
            if (_selection[field]?.value.trim() != value.trim()) {
              setState(() {
                _selection[field] = null;
              });
            }
          },
        ),
        if (selected != null) ...[
          const SizedBox(height: 6),
          _EvidenceTile(suggestion: selected),
        ],
      ],
    );
  }

  void _resetToOriginal() {
    setState(() {
      for (final field in PartyField.values) {
        widget.controllers[field]!.text = widget.previousValues[field] ?? '';
        _selection[field] = null;
      }
    });
  }

  void _selectSuggestion(
    PartyField field,
    PartyOcrFieldSuggestion suggestion,
  ) {
    setState(() {
      _selection[field] = suggestion;
      widget.controllers[field]!.text = suggestion.value;
    });
  }

  Color _confidenceColor(PartyOcrConfidence confidence) {
    switch (confidence) {
      case PartyOcrConfidence.high:
        return Colors.green.shade700;
      case PartyOcrConfidence.medium:
        return Colors.amber.shade700;
      case PartyOcrConfidence.low:
        return Colors.red.shade700;
    }
  }

  String _confidenceLabel(PartyOcrConfidence confidence) {
    switch (confidence) {
      case PartyOcrConfidence.high:
        return 'High';
      case PartyOcrConfidence.medium:
        return 'Medium';
      case PartyOcrConfidence.low:
        return 'Low';
    }
  }
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({required this.suggestion});

  final PartyOcrFieldSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall;
    final evidence = suggestion.evidence;
    final highlight = suggestion.highlight;

    if (highlight == null ||
        highlight.isEmpty ||
        !evidence.toLowerCase().contains(highlight.toLowerCase())) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Evidence: $evidence', style: style),
          Text(suggestion.reason,
              style: style?.copyWith(fontStyle: FontStyle.italic)),
        ],
      );
    }

    final lowerEvidence = evidence.toLowerCase();
    final lowerHighlight = highlight.toLowerCase();
    final start = lowerEvidence.indexOf(lowerHighlight);
    final end = start + highlight.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: style,
            children: [
              const TextSpan(text: 'Evidence: '),
              TextSpan(text: evidence.substring(0, start)),
              TextSpan(
                text: evidence.substring(start, end),
                style: style?.copyWith(fontWeight: FontWeight.w600),
              ),
              TextSpan(text: evidence.substring(end)),
            ],
          ),
        ),
        Text(suggestion.reason,
            style: style?.copyWith(fontStyle: FontStyle.italic)),
      ],
    );
  }
}
