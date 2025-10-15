import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../app/di.dart';
import '../../../ocr/services/ocr_service.dart';
import '../../../shared/domain/normalizers.dart';

enum CaptureField {
  partyName,
  partyDepartment,
  partyEmail,
  makeModel,
  assetTag,
  serviceTag,
  serialNumber,
  imei,
  warrantyExpiry,
}

extension CaptureFieldMetadata on CaptureField {
  String get label {
    switch (this) {
      case CaptureField.partyName:
        return 'Name';
      case CaptureField.partyDepartment:
        return 'Department';
      case CaptureField.partyEmail:
        return 'Email';
      case CaptureField.makeModel:
        return 'Make / Model';
      case CaptureField.assetTag:
        return 'Asset Tag';
      case CaptureField.serviceTag:
        return 'Service Tag';
      case CaptureField.serialNumber:
        return 'Serial Number';
      case CaptureField.imei:
        return 'IMEI';
      case CaptureField.warrantyExpiry:
        return 'Warranty Expiry';
    }
  }

  double get preferredAspectRatio {
    switch (this) {
      case CaptureField.partyName:
      case CaptureField.partyDepartment:
        return 5;
      case CaptureField.partyEmail:
        return 6;
      case CaptureField.assetTag:
      case CaptureField.serviceTag:
      case CaptureField.serialNumber:
      case CaptureField.imei:
        return 7;
      case CaptureField.makeModel:
        return 4;
      case CaptureField.warrantyExpiry:
        return 3;
    }
  }

  List<double> get presetRatios {
    if (this == CaptureField.partyName ||
        this == CaptureField.partyDepartment ||
        this == CaptureField.partyEmail) {
      return const [4, 5, 6, 8];
    }
    if (this == CaptureField.makeModel) {
      return const [4, 5, 6];
    }
    if (this == CaptureField.assetTag ||
        this == CaptureField.serviceTag ||
        this == CaptureField.serialNumber ||
        this == CaptureField.imei) {
      return const [6, 8, 12];
    }
    if (this == CaptureField.warrantyExpiry) {
      return const [3, 4, 5];
    }
    return const [4];
  }
}

class FieldCaptureResult {
  FieldCaptureResult({
    required this.value,
    required this.imagePath,
    this.confidence,
  });

  final String value;
  final String imagePath;
  final double? confidence;
}

class FieldCaptureSheet {
  FieldCaptureSheet(this.ref);

  final WidgetRef ref;
  final ImagePicker _picker = ImagePicker();

  Future<FieldCaptureResult?> capture({
    required BuildContext context,
    required CaptureField field,
    ImageSource? source,
  }) async {
    final pickerSource = source ??
        await showModalBottomSheet<ImageSource>(
          context: context,
          builder: (context) => _CaptureSourceSheet(field: field),
        );
    if (!context.mounted || pickerSource == null) return null;

    final file =
        await _picker.pickImage(source: pickerSource, imageQuality: 95);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (!context.mounted) return null;
    final cropped = await _showCropper(context, bytes, field);
    if (!context.mounted || cropped == null) return null;

    final saved = await _writeBytesToTemp(cropped, suffix: field.name);
    final ocrService = ref.read(ocrServiceProvider);
    final logger = ref.read(appLoggerProvider);

    try {
      final result = await ocrService.analyze(saved, hints: {
        'targetField': field.name,
      });
      final value = _extractValue(field, result);
      if (value == null || value.isEmpty) {
        return FieldCaptureResult(
            value: '', imagePath: saved.path, confidence: result.confidence);
      }
      return FieldCaptureResult(
          value: value, imagePath: saved.path, confidence: result.confidence);
    } catch (error, stack) {
      logger.error('Field capture OCR failed for ${field.name}',
          error: error, stackTrace: stack);
      return FieldCaptureResult(value: '', imagePath: saved.path);
    }
  }

  Future<File> _writeBytesToTemp(Uint8List bytes,
      {required String suffix}) async {
    final directory = await getTemporaryDirectory();
    final filename =
        'capture_${suffix}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File(p.join(directory.path, filename));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<Uint8List?> _showCropper(
      BuildContext context, Uint8List bytes, CaptureField field) async {
    return showDialog<Uint8List?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _FieldCropDialog(imageBytes: bytes, field: field),
    );
  }

  String? _extractValue(CaptureField field, OcrResult result) {
    final raw = (result.fields['rawText'] as String?)?.trim() ?? '';
    switch (field) {
      case CaptureField.partyName:
        return raw.split('\n').firstOrNull?.trim() ?? raw;
      case CaptureField.partyDepartment:
        if (raw.contains('@')) {
          final segments = raw.split(RegExp(r'[\n,]'));
          if (segments.length >= 2) {
            return segments[segments.length - 2].trim();
          }
        }
        return raw;
      case CaptureField.partyEmail:
        final emailRegex = RegExp(r'[^@\s]+@[^@\s]+\.[^@\s]+');
        final match = emailRegex.firstMatch(raw);
        return match?.group(0)?.toLowerCase() ?? raw;
      case CaptureField.makeModel:
        final normalized = normalizeDellLatitudeModel(raw.split('\n').first);
        return (normalized == null || normalized.isEmpty)
            ? raw.split('\n').first.trim()
            : normalized;
      case CaptureField.assetTag:
        final sanitized =
            raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
        return sanitized;
      case CaptureField.serviceTag:
      case CaptureField.serialNumber:
        final sanitized =
            raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
        return sanitized;
      case CaptureField.imei:
        final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.length >= 15) {
          return digits.substring(0, 15);
        }
        return digits;
      case CaptureField.warrantyExpiry:
        final digits = raw.replaceAll(RegExp(r'[^0-9/]'), '');
        return digits;
    }
  }
}

class _CaptureSourceSheet extends StatelessWidget {
  const _CaptureSourceSheet({required this.field});

  final CaptureField field;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('Capture ${field.label}'),
            subtitle: const Text('Select source'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Photo Library'),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _FieldCropDialog extends StatefulWidget {
  const _FieldCropDialog({required this.imageBytes, required this.field});

  final Uint8List imageBytes;
  final CaptureField field;

  @override
  State<_FieldCropDialog> createState() => _FieldCropDialogState();
}

class _FieldCropDialogState extends State<_FieldCropDialog> {
  final CropController _controller = CropController();
  bool _isCropping = false;
  double _aspectRatio = 0;
  Completer<Uint8List>? _croppedCompleter;

  @override
  void initState() {
    super.initState();
    _aspectRatio = widget.field.preferredAspectRatio;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.88,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Crop(
                  image: widget.imageBytes,
                  controller: _controller,
                  aspectRatio: _aspectRatio > 0 ? _aspectRatio : null,
                  onCropped: (bytes) {
                    _croppedCompleter?.complete(bytes);
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: widget.field.presetRatios
                    .map(
                      (ratio) => ChoiceChip(
                        label: Text('${ratio.toStringAsFixed(1)}:1'),
                        selected: _aspectRatio == ratio,
                        onSelected: (value) {
                          if (!value) return;
                          setState(() => _aspectRatio = ratio);
                          _controller.aspectRatio = ratio;
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  TextButton(
                    onPressed:
                        _isCropping ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _isCropping ? null : _handleCrop,
                    icon: _isCropping
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.check),
                    label: const Text('Use Selection'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCrop() async {
    setState(() => _isCropping = true);
    _croppedCompleter = Completer<Uint8List>();
    _controller.crop();
    try {
      final bytes = await _croppedCompleter!.future;
      if (!mounted) return;
      setState(() => _isCropping = false);
      Navigator.of(context).pop(bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCropping = false);
      Navigator.of(context).pop();
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    for (final element in this) {
      return element;
    }
    return null;
  }
}
