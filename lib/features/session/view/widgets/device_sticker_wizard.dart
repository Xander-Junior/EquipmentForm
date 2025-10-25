import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/di.dart';
import '../../../shared/services/image_normalizer.dart';
import '../../ocr/device_ocr_analyzer.dart';
import '../../../shared/domain/normalizers.dart';

class DeviceStickerWizardResult {
  const DeviceStickerWizardResult({
    required this.appliedValues,
    required this.previousValues,
    this.sentToDiagnostics = false,
  });

  final Map<String, String> appliedValues;
  final Map<String, String> previousValues;
  final bool sentToDiagnostics;
}

class DeviceStickerWizard {
  DeviceStickerWizard(
    this.ref, {
    DeviceOcrAnalyzer? analyzer,
  }) : _analyzer = analyzer ?? const DeviceOcrAnalyzer();

  static const double _kSharpnessThreshold = 55;
  static const double _kLowConfidenceThreshold = 0.62;

  final WidgetRef ref;
  final ImagePicker _picker = ImagePicker();
  final DeviceOcrAnalyzer _analyzer;

  Future<DeviceStickerWizardResult?> captureSticker({
    required BuildContext context,
    required Map<String, String> currentValues,
  }) async {
    final file = await _selectImage(context);
    if (file == null) return null;
    if (!context.mounted) return null;
    return processImage(
        context: context, image: file, currentValues: currentValues);
  }

  @visibleForTesting
  Future<DeviceStickerWizardResult?> processImage({
    required BuildContext context,
    required File image,
    required Map<String, String> currentValues,
  }) async {
    final normalizer = ref.read(imageNormalizerProvider);
    final ocrService = ref.read(ocrServiceProvider);
    final legibilityBoost = ref.read(legibilityPreferenceProvider);

    final normalized = await normalizer.normalize(
      image,
      improveLegibility: legibilityBoost,
      cropPreset: ImageCropPreset.deviceSticker,
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

    final ocrResult = await ocrService.analyze(normalized.file);
    final analysis = _analyzer.analyze(ocrResult.fields);

    if (!context.mounted) return null;

    if (ocrResult.confidence < _kLowConfidenceThreshold) {
      final proceed = await _confirmLowConfidence(
        context,
        ocrResult.confidence,
      );
      if (!proceed) {
        return null;
      }
    }

    final diagnostics = ref.read(diagnosticsRecorderProvider);
    final diagnosticsMetadata = {
      'confidence': ocrResult.confidence,
      'sharpness': normalized.sharpness,
      'brightness': normalized.brightness,
    };

    if (!context.mounted) return null;

    final result = await showDialog<DeviceStickerWizardResult>(
      context: context,
      builder: (context) => _DeviceStickerWizardDialog(
        analysis: analysis,
        confidence: ocrResult.confidence,
        imageWasPreprocessed: normalized.legibilityApplied,
        currentValues: currentValues,
        sharpness: normalized.sharpness,
      ),
    );

    if (!context.mounted) return null;

    if (result == null) return null;

    final sanitizedValues = _sanitizeStickerValues(result.appliedValues);

    if (result.sentToDiagnostics) {
      final metadata = {
        ...diagnosticsMetadata,
        'appliedValues': sanitizedValues,
        'previousValues': result.previousValues,
      };
      await diagnostics.capture(
        image: normalized.file,
        metadata: metadata,
        ocrFields: ocrResult.fields,
      );
    }

    return DeviceStickerWizardResult(
      appliedValues: sanitizedValues,
      previousValues: result.previousValues,
      sentToDiagnostics: result.sentToDiagnostics,
    );
  }

  Future<File?> _selectImage(BuildContext context) async {
    final choice = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Capture Device Sticker'),
        content: const Text('Choose how to capture the device sticker image:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
            child: const Text('Take Photo'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
            child: const Text('Choose from Gallery'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (choice == null) return null;

    final XFile? picked = await _picker.pickImage(
      source: choice,
      imageQuality: 100,
      preferredCameraDevice: CameraDevice.rear,
    );

    return picked != null ? File(picked.path) : null;
  }

  Future<bool> _confirmLowConfidence(
    BuildContext context,
    double confidence,
  ) async {
    final percent = (confidence * 100).clamp(0, 100).toStringAsFixed(1);
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Low confidence result'),
            content: Text(
              'OCR confidence is $percent%. Retake the photo or continue with the suggestions?',
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

  Map<String, String> _sanitizeStickerValues(Map<String, String> values) {
    final sanitized = Map<String, String>.from(values);

    final assetRaw = sanitized['assetTag'];
    if (assetRaw != null && assetRaw.trim().isNotEmpty) {
      final canonical = normalizeAssetTag(assetRaw);
      sanitized['assetTag'] = canonical ??
          assetRaw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9\-]'), '');
    }

    final serviceRaw = sanitized['serviceTag'];
    if (serviceRaw != null && serviceRaw.trim().isNotEmpty) {
      sanitized['serviceTag'] = serviceRaw
          .trim()
          .toUpperCase()
          .replaceAll(RegExp(r'[^A-Z0-9\-]'), '');
    }

    final imeiRaw = sanitized['imei'];
    if (imeiRaw != null && imeiRaw.trim().isNotEmpty) {
      sanitized['imei'] = normalizeImei(imeiRaw) ?? imeiRaw.replaceAll(' ', '');
    }

    final warrantyRaw = sanitized['warrantyExpiry'];
    if (warrantyRaw != null && warrantyRaw.trim().isNotEmpty) {
      final iso = normalizeWarrantyExpiry(warrantyRaw);
      sanitized['warrantyExpiry'] = iso == null
          ? warrantyRaw.trim()
          : formatWarrantyExpiryForDisplay(iso);
    }

    final modelRaw = sanitized['makeModel'];
    if (modelRaw != null && modelRaw.trim().isNotEmpty) {
      final trimmed = modelRaw.trim();
      final normalized = normalizeDellLatitudeModel(trimmed)?.trim();
      if (normalized == null || normalized.isEmpty) {
        sanitized['makeModel'] = _formatModelDisplay(trimmed);
      } else {
        final lower = trimmed.toLowerCase();
        sanitized['makeModel'] = lower.contains('latitude')
            ? 'Dell Latitude ${normalized.toUpperCase()}'
            : _formatModelDisplay(trimmed);
      }
    }

    return sanitized;
  }
}

String _formatModelDisplay(String input) {
  return input.split(' ').map((word) {
    if (word.isEmpty) return word;
    final upper = word.toUpperCase();
    if (['HP', 'ASUS', 'MSI', 'USB', 'SSD', 'HDD', 'RAM', 'CPU', 'GPU']
        .contains(upper)) {
      return upper;
    }
    final lower = word.toLowerCase();
    if (lower == 'dell') return 'Dell';
    if (lower == 'optiplex') return 'OptiPlex';
    if (lower == 'latitude') return 'Latitude';
    if (lower == 'thinkpad') return 'ThinkPad';
    if (lower == 'macbook') return 'MacBook';
    if (lower == 'probook') return 'ProBook';
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }).join(' ');
}

class _DeviceStickerWizardDialog extends StatefulWidget {
  const _DeviceStickerWizardDialog({
    required this.analysis,
    required this.confidence,
    required this.imageWasPreprocessed,
    required this.currentValues,
    required this.sharpness,
  });

  final DeviceOcrAnalysis analysis;
  final double confidence;
  final bool imageWasPreprocessed;
  final Map<String, String> currentValues;
  final double sharpness;

  @override
  State<_DeviceStickerWizardDialog> createState() =>
      _DeviceStickerWizardDialogState();
}

class _DeviceStickerWizardDialogState
    extends State<_DeviceStickerWizardDialog> {
  final Map<String, String> _selectedValues = {};
  bool _sentToDiagnostics = false;

  static const List<String> _deviceFields = [
    'assetTag',
    'serviceTag',
    'makeModel',
    'warrantyExpiry',
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with primary suggestions
    for (final field in _deviceFields) {
      final suggestion = widget.analysis.primarySuggestionFor(field);
      if (suggestion != null) {
        _selectedValues[field] = suggestion.value;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final confidence = widget.confidence * 100;
    final sharpness = widget.sharpness;

    return AlertDialog(
      title: const Text('Device Sticker OCR Results'),
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
              for (final field in _deviceFields) ...[
                _buildFieldSection(context, field),
                if (field != _deviceFields.last) const SizedBox(height: 20),
              ],
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text('OCR Evidence'),
                subtitle: const Text('Show extracted lines'),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.analysis.lines.join('\\n'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontFamily: 'monospace',
                          ),
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
          onPressed: () => Navigator.of(context).pop(),
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
        ElevatedButton(
          onPressed: _selectedValues.isNotEmpty ? _applyChanges : null,
          child: const Text('Apply'),
        ),
      ],
    );
  }

  Widget _buildFieldSection(BuildContext context, String field) {
    final suggestions = widget.analysis.suggestionsFor(field);
    final fieldLabel = _getFieldLabel(field);
    final currentValue = widget.currentValues[field] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          fieldLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (currentValue.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current: $currentValue',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (suggestions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'No suggestions found',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...suggestions.take(3).map((suggestion) {
            final isSelected = _selectedValues[field] == suggestion.value;
            final accent = _confidenceColor(suggestion.confidence);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedValues.remove(field);
                    } else {
                      _selectedValues[field] = suggestion.value;
                    }
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? accent : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              suggestion.value,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected ? accent : null,
                                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _confidenceColor(suggestion.confidence),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _confidenceLabel(suggestion.confidence),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (suggestion.evidence.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _EvidenceTile(suggestion: suggestion),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  String _getFieldLabel(String field) {
    switch (field) {
      case 'assetTag':
        return 'Asset Tag';
      case 'serviceTag':
        return 'Service Tag';
      case 'makeModel':
        return 'Make / Model';
      case 'warrantyExpiry':
        return 'Warranty Expiry';
      default:
        return field;
    }
  }

  Color _confidenceColor(DeviceOcrConfidence confidence) {
    switch (confidence) {
      case DeviceOcrConfidence.high:
        return Colors.green.shade700;
      case DeviceOcrConfidence.medium:
        return Colors.amber.shade700;
      case DeviceOcrConfidence.low:
        return Colors.red.shade700;
    }
  }

  String _confidenceLabel(DeviceOcrConfidence confidence) {
    switch (confidence) {
      case DeviceOcrConfidence.high:
        return 'High';
      case DeviceOcrConfidence.medium:
        return 'Medium';
      case DeviceOcrConfidence.low:
        return 'Low';
    }
  }

  void _applyChanges() {
    final previousValues = Map<String, String>.from(widget.currentValues);
    Navigator.of(context).pop(
      DeviceStickerWizardResult(
        appliedValues: Map<String, String>.from(_selectedValues),
        previousValues: previousValues,
        sentToDiagnostics: _sentToDiagnostics,
      ),
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  const _EvidenceTile({required this.suggestion});

  final DeviceOcrFieldSuggestion suggestion;

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
                style: style?.copyWith(
                  backgroundColor: Colors.yellow.shade200,
                  fontWeight: FontWeight.bold,
                ),
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
