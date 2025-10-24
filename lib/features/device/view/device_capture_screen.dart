import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../app/di.dart';
import '../../../app/router.dart';
import '../../../data/models/session.dart';
import '../../ocr/state/ocr_controller.dart';
import '../../ocr/state/ocr_state.dart';
import '../../shared/domain/device_kind.dart';
import '../../shared/domain/normalizers.dart';
import '../../shared/widgets/input_formatters.dart';
import '../../session/view/widgets/device_sticker_wizard.dart';
import '../../session/view/widgets/field_capture_sheet.dart';

class DeviceCaptureScreen extends ConsumerStatefulWidget {
  const DeviceCaptureScreen({super.key, this.formType});

  final FormType? formType;

  static const List<String> sampleAssets = [
    'assets/samples/ocr/eqpt_details/IMG_1577.jpg',
    'assets/samples/ocr/eqpt_details/IMG_1578.jpg',
    'assets/samples/ocr/eqpt_details/IMG_2009.jpg',
    'assets/samples/ocr/eqpt_details/IMG_2010.jpg',
  ];

  @override
  ConsumerState<DeviceCaptureScreen> createState() =>
      _DeviceCaptureScreenState();
}

class _DeviceCaptureScreenState extends ConsumerState<DeviceCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  late final Map<String, TextEditingController> _controllers;
  late final ProviderSubscription<OcrState> _ocrSubscription;
  late final DeviceStickerWizard _stickerWizard;

  DeviceKind _deviceKind = DeviceKind.laptop;
  final Set<String> _selectedAccessories = <String>{};
  bool _isProcessingImage = false;
  File? _lastAnalyzedImage;

  static const List<String> _accessoryOptions = <String>[
    'Adapter',
    'Laptop Bag',
    'Mouse',
    'Keyboard',
    'USB-C Hub',
  ];

  @override
  void initState() {
    super.initState();
    _stickerWizard = DeviceStickerWizard(ref);
    _controllers = {
      'name': TextEditingController(),
      'department': TextEditingController(),
      'email': TextEditingController(),
      'makeModel': TextEditingController(),
      'assetTag': TextEditingController(),
      'serviceTag': TextEditingController(),
      'serial': TextEditingController(),
      'imei': TextEditingController(),
      'warrantyExpiry': TextEditingController(),
    };

    _ocrSubscription = ref.listenManual<OcrState>(
      ocrControllerProvider,
      (previous, next) {
        final result = next.result;
        if (result == null || result == previous?.result) return;
        for (final entry in result.fields.entries) {
          final key = entry.key;
          if (_controllers.containsKey(key)) {
            final controller = _controllers[key]!;
            final value = key == 'warrantyExpiry'
                ? formatWarrantyExpiryForDisplay(entry.value?.toString())
                : entry.value?.toString() ?? '';
            controller
              ..text = value
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: controller.text.length),
              );
          }
        }
        if (result.fields['deviceKind'] is String) {
          final value = result.fields['deviceKind'] as String;
          final match = DeviceKind.values.tryFirstWhere((k) => k.name == value);
          if (match != null) {
            setState(() => _deviceKind = match);
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _ocrSubscription.close();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.formType?.name ?? 'unknown';
    final ocrState = ref.watch(ocrControllerProvider);
    final controller = ref.read(ocrControllerProvider.notifier);
    final lowConfidence = ocrState.result != null &&
        ocrState.result!.confidence < OcrController.lowConfidenceThreshold;
    final improveLegibility = ref.watch(legibilityPreferenceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Device Capture — ${label.toUpperCase()}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.pushNamed(AppRoute.diagnostics.name),
            tooltip: 'Diagnostics',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _CaptureHintsCard(
                  onDemo: () => _analyzeSample(controller),
                  onCamera: () => _pickImage(ImageSource.camera, controller),
                  onGallery: () => _pickImage(ImageSource.gallery, controller),
                  onFullSticker: () => _handleFullStickerScan(context),
                  improveLegibility: improveLegibility,
                  onToggleLegibility: (value) => ref
                      .read(legibilityPreferenceProvider.notifier)
                      .state = value,
                  isBusy: _isProcessingImage || ocrState.isProcessing,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<DeviceKind>(
                  initialValue: _deviceKind,
                  decoration: const InputDecoration(
                      labelText: 'Device Kind', border: OutlineInputBorder()),
                  onChanged: (value) =>
                      setState(() => _deviceKind = value ?? DeviceKind.other),
                  items: DeviceKind.values
                      .map((kind) => DropdownMenuItem(
                            value: kind,
                            child: Text(kind.label),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _accessoryOptions
                      .map(
                        (option) => FilterChip(
                          label: Text(option),
                          selected: _selectedAccessories.contains(option),
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _selectedAccessories.add(option);
                              } else {
                                _selectedAccessories.remove(option);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                _ReviewPanel(
                  controllers: _controllers,
                  lowConfidence: lowConfidence,
                  confidence: ocrState.result?.confidence ?? 0,
                  isProcessing: ocrState.isProcessing,
                  lastImage: _lastAnalyzedImage,
                  deviceKind: _deviceKind,
                  height: 360,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: ElevatedButton(
              onPressed: () {
                final payload = {
                  'deviceKind': _deviceKind.name,
                  'accessories': _selectedAccessories.toList(),
                  'fields': {
                    for (final entry in _controllers.entries)
                      entry.key: entry.value.text.trim(),
                  },
                  'confidence': ocrState.result?.confidence ?? 0,
                };
                context.goNamed(
                  AppRoute.review.name,
                  extra: {
                    'formType': widget.formType,
                    ...payload,
                  },
                );
              },
              child: const Text('Review Summary'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, OcrController controller) async {
    try {
      setState(() => _isProcessingImage = true);
      final XFile? picked =
          await _picker.pickImage(source: source, imageQuality: 95);
      if (picked == null) {
        setState(() => _isProcessingImage = false);
        return;
      }
      final improveLegibility = ref.read(legibilityPreferenceProvider);
      final normalizer = ref.read(imageNormalizerProvider);
      final normalized = await normalizer.normalize(
        File(picked.path),
        improveLegibility: improveLegibility,
      );
      _lastAnalyzedImage = normalized.file;
      final usedPreprocessing = normalized.legibilityApplied ||
          normalized.convertedHeic ||
          normalized.reoriented;
      await controller.analyze(normalized.file,
          usedPreprocessing: usedPreprocessing);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process image: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessingImage = false);
      }
    }
  }

  Future<void> _analyzeSample(OcrController controller) async {
    final asset = DeviceCaptureScreen.sampleAssets[
        Random().nextInt(DeviceCaptureScreen.sampleAssets.length)];
    final file = await _writeAssetToTempFile(asset);
    final normalizer = ref.read(imageNormalizerProvider);
    final improveLegibility = ref.read(legibilityPreferenceProvider);
    final normalized =
        await normalizer.normalize(file, improveLegibility: improveLegibility);
    _lastAnalyzedImage = normalized.file;
    await controller.analyze(normalized.file,
        usedPreprocessing: normalized.legibilityApplied);
  }

  Future<void> _handleFullStickerScan(BuildContext context) async {
    if (!mounted) return;

    final currentValues = {
      for (final entry in _controllers.entries)
        entry.key: entry.value.text.trim(),
    };

    final result = await _stickerWizard.captureSticker(
      context: context,
      currentValues: currentValues,
    );

    if (!mounted || result == null) return;
    if (!context.mounted) return;

    // Apply the results to controllers
    for (final entry in result.appliedValues.entries) {
      final controller = _controllers[entry.key];
      if (controller != null) {
        controller.text = entry.value;
      }
    }

    // Show success message with undo option
    if (!mounted || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Applied device sticker OCR results.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // Restore previous values
              for (final entry in result.previousValues.entries) {
                final controller = _controllers[entry.key];
                if (controller != null) {
                  controller.text = entry.value;
                }
              }
            },
          ),
        ),
      );
  }

  Future<File> _writeAssetToTempFile(String assetPath) async {
    final bytes = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, assetPath.split('/').last));
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return file;
  }
}

class _CaptureHintsCard extends StatelessWidget {
  const _CaptureHintsCard({
    required this.onDemo,
    required this.onCamera,
    required this.onGallery,
    required this.onFullSticker,
    required this.improveLegibility,
    required this.onToggleLegibility,
    required this.isBusy,
  });

  final VoidCallback onDemo;
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback onFullSticker;
  final bool improveLegibility;
  final ValueChanged<bool> onToggleLegibility;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blueGrey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Capture Tips',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton(
                    onPressed: isBusy ? null : onDemo,
                    child: const Text('Analyze demo asset')),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
                '• Find bright, even lighting. Avoid shadows across text.'),
            const Text(
                '• Hold steady for two seconds. Line up the form within guides.'),
            const Text(
                '• Toggle legibility to enhance faint prints before OCR.'),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Improve legibility'),
              subtitle:
                  const Text('Applies grayscale and sharpening before OCR'),
              trailing: Switch.adaptive(
                value: improveLegibility,
                onChanged: isBusy ? null : onToggleLegibility,
              ),
              onTap:
                  isBusy ? null : () => onToggleLegibility(!improveLegibility),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isBusy ? null : onGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Import'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: isBusy ? null : onFullSticker,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan Full Device Sticker'),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.blue.shade50,
                foregroundColor: Colors.blue.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewPanel extends StatelessWidget {
  const _ReviewPanel({
    required this.controllers,
    required this.lowConfidence,
    required this.confidence,
    required this.isProcessing,
    required this.lastImage,
    required this.deviceKind,
    this.height = 320,
  });

  final Map<String, TextEditingController> controllers;
  final bool lowConfidence;
  final double confidence;
  final bool isProcessing;
  final File? lastImage;
  final DeviceKind deviceKind;
  final double height;

  static const List<_FieldConfig> _fields = <_FieldConfig>[
    _FieldConfig('makeModel', 'Make / Model'),
    _FieldConfig('assetTag', 'Asset Tag'),
    _FieldConfig('serviceTag', 'Service Tag'),
    _FieldConfig('serial', 'Serial'),
    _FieldConfig('imei', 'IMEI'),
    _FieldConfig('warrantyExpiry', 'Warranty Expiry (DD/MM/YYYY)'),
    _FieldConfig('name', 'Name'),
    _FieldConfig('department', 'Department'),
    _FieldConfig('email', 'Email'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (lowConfidence)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              'Low confidence reading (${(confidence * 100).toStringAsFixed(1)}%). '
              'Confirm details below or retake the photo for best accuracy.',
            ),
          ),
        if (lastImage != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(lastImage!, height: 120, fit: BoxFit.cover),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: height,
          child: Opacity(
            opacity: isProcessing ? 0.5 : 1,
            child: IgnorePointer(
              ignoring: isProcessing,
              child: ListView.separated(
                itemCount: _fields.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final field = _fields[index];
                  final controller = controllers[field.key]!;
                  if (field.key == 'makeModel' &&
                      deviceKind == DeviceKind.laptop) {
                    return Row(
                      children: [
                        const Chip(
                          label: Text('DELL·LATITUDE'),
                          avatar: Icon(Icons.laptop, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            textCapitalization: TextCapitalization.characters,
                            inputFormatters: const [UppercaseFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'Model number',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Consumer(
                          builder: (context, ref, _) => IconButton(
                            onPressed: isProcessing
                                ? null
                                : () => _showFieldCapture(
                                    context, ref, field, controllers),
                            icon: const Icon(Icons.crop_free),
                            tooltip: 'Capture ${field.label}',
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          decoration: InputDecoration(
                            labelText: field.label,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Consumer(
                        builder: (context, ref, _) => IconButton(
                          onPressed: isProcessing
                              ? null
                              : () => _showFieldCapture(
                                  context, ref, field, controllers),
                          icon: const Icon(Icons.crop_free),
                          tooltip: 'Capture ${field.label}',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  static void _showFieldCapture(BuildContext context, WidgetRef ref,
      _FieldConfig field, Map<String, TextEditingController> controllers) {
    final captureField = _mapToCaptureField(field.key);
    if (captureField == null) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FieldCaptureBottomSheet(
        field: captureField,
        onResult: (value) {
          final controller = controllers[field.key];
          if (controller != null && value.isNotEmpty) {
            if (field.key == 'makeModel') {
              final normalized = normalizeDellLatitudeModel(value) ?? value;
              controller.text = normalized.trim().toUpperCase();
            } else {
              controller.text = value;
            }
          }
        },
      ),
    );
  }

  static CaptureField? _mapToCaptureField(String fieldKey) {
    switch (fieldKey) {
      case 'makeModel':
        return CaptureField.makeModel;
      case 'assetTag':
        return CaptureField.assetTag;
      case 'serviceTag':
        return CaptureField.serviceTag;
      case 'serial':
        return CaptureField.serialNumber;
      case 'imei':
        return CaptureField.imei;
      case 'warrantyExpiry':
        return CaptureField.warrantyExpiry;
      case 'name':
        return CaptureField.partyName;
      case 'department':
        return CaptureField.partyDepartment;
      case 'email':
        return CaptureField.partyEmail;
      default:
        return null;
    }
  }
}

class _FieldCaptureBottomSheet extends ConsumerWidget {
  const _FieldCaptureBottomSheet({
    required this.field,
    required this.onResult,
  });

  final CaptureField field;
  final ValueChanged<String> onResult;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Capture ${field.label}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text('Choose how to capture this field:'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _captureField(context, ref, ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _captureField(context, ref, ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureField(
      BuildContext context, WidgetRef ref, ImageSource source) async {
    try {
      Navigator.of(context).pop(); // Close the bottom sheet

      final captureSheet = FieldCaptureSheet(ref);
      final result = await captureSheet.capture(
        context: context,
        field: field,
        source: source,
      );

      if (result != null && result.value.isNotEmpty) {
        onResult(result.value);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture field: $error')),
        );
      }
    }
  }
}

class _FieldConfig {
  const _FieldConfig(this.key, this.label);
  final String key;
  final String label;
}

extension<T> on Iterable<T> {
  T? tryFirstWhere(bool Function(T element) test) {
    for (final value in this) {
      if (test(value)) return value;
    }
    return null;
  }
}
