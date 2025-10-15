import 'dart:io';
import 'dart:math' as math;

import 'package:exif/exif.dart';
import 'package:heic_to_jpg/heic_to_jpg.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../app/di.dart';
import '../../../core/img_compat.dart' as img_compat;

enum ImageCropPreset { profileCard, deviceSticker }

class NormalizedImage {
  const NormalizedImage({
    required this.file,
    this.convertedHeic = false,
    this.reoriented = false,
    this.legibilityApplied = false,
    this.sharpness = 0,
    this.brightness = 0,
  });

  final File file;
  final bool convertedHeic;
  final bool reoriented;
  final bool legibilityApplied;
  final double sharpness;
  final double brightness;
}

class ImageNormalizer {
  ImageNormalizer({required this.logger});

  final AppLogger logger;

  Future<NormalizedImage> normalize(
    File input, {
    required bool improveLegibility,
    ImageCropPreset? cropPreset,
  }) async {
    File workingFile = input;
    bool convertedHeic = false;
    bool reoriented = false;

    final extension = workingFile.path.toLowerCase();
    if (extension.endsWith('.heic') || extension.endsWith('.heif')) {
      final convertedPath = await HeicToJpg.convert(workingFile.path);
      if (convertedPath != null) {
        workingFile = File(convertedPath);
        convertedHeic = true;
      }
    }

    final bytes = await workingFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      logger.info(
          'ImageNormalizer: failed to decode image, returning original file');
      return NormalizedImage(
        file: workingFile,
        convertedHeic: convertedHeic,
        sharpness: 0,
        brightness: 0,
      );
    }

    img.Image oriented = decoded;
    try {
      final exifData = await readExifFromBytes(bytes);
      final orientationTag = exifData['Image Orientation'];
      if (orientationTag != null) {
        final printable = orientationTag.printable.toLowerCase();
        if (printable.contains('180')) {
          oriented = img.copyRotate(oriented, angle: 180);
          reoriented = true;
        } else if (printable.contains('90')) {
          oriented = img.copyRotate(oriented, angle: 90);
          reoriented = true;
        } else if (printable.contains('270')) {
          oriented = img.copyRotate(oriented, angle: -90);
          reoriented = true;
        }
      }
    } catch (error, stack) {
      logger.error('ImageNormalizer: failed to parse EXIF orientation',
          error: error, stackTrace: stack);
    }

    img.Image cropped = _applyCrop(oriented, cropPreset);

    final metricsSource = img.grayscale(cropped.clone());
    final sharpness = _computeSharpness(metricsSource);
    final brightness = _computeAverageLuminance(metricsSource);

    img.Image processed = cropped;
    bool legibilityApplied = false;
    if (improveLegibility) {
      processed = img.grayscale(processed);
      processed = img_compat.unsharp(
        processed,
        radius: 2,
        amount: 1.3,
        threshold: 10,
      );
      processed = _applyThreshold(processed);
      processed = img.adjustColor(processed, contrast: 1.18, brightness: 5);
      legibilityApplied = true;
    }

    if (!convertedHeic &&
        !reoriented &&
        !legibilityApplied &&
        cropPreset == null) {
      return NormalizedImage(
        file: workingFile,
        sharpness: sharpness,
        brightness: brightness,
      );
    }

    final tempDir = await getTemporaryDirectory();
    final baseName = p.basenameWithoutExtension(workingFile.path);
    final suffix = legibilityApplied ? '_preproc' : '_normalized';
    final outputPath = p.join(tempDir.path, '$baseName$suffix.jpg');
    final encoded = img.encodeJpg(processed, quality: 92);
    final resultFile = File(outputPath);
    await resultFile.writeAsBytes(encoded, flush: true);

    logger.info(
      'ImageNormalizer: normalized file ${input.path} -> ${resultFile.path} '
      '(heicConverted=$convertedHeic, reoriented=$reoriented, legibility=$legibilityApplied)',
    );

    return NormalizedImage(
      file: resultFile,
      convertedHeic: convertedHeic,
      reoriented: reoriented,
      legibilityApplied: legibilityApplied,
      sharpness: sharpness,
      brightness: brightness,
    );
  }

  img.Image _applyCrop(img.Image image, ImageCropPreset? preset) {
    if (preset == null) return image;
    final width = image.width;
    final height = image.height;
    if (width < 10 || height < 10) return image;

    double widthFactor;
    double heightFactor;
    switch (preset) {
      case ImageCropPreset.profileCard:
        widthFactor = 0.82;
        heightFactor = 0.65;
        break;
      case ImageCropPreset.deviceSticker:
        widthFactor = 0.9;
        heightFactor = 0.55;
        break;
    }

    final cropWidth = (width * widthFactor).clamp(1, width).round();
    final cropHeight = (height * heightFactor).clamp(1, height).round();
    final left = ((width - cropWidth) / 2).round();
    final top = ((height - cropHeight) / 2).round();
    return img.copyCrop(image,
        x: left, y: top, width: cropWidth, height: cropHeight);
  }

  double _computeSharpness(img.Image grayImage) {
    if (grayImage.width < 3 || grayImage.height < 3) return 0;
    double sum = 0;
    double sumSq = 0;
    int count = 0;
    for (var y = 1; y < grayImage.height - 1; y++) {
      for (var x = 1; x < grayImage.width - 1; x++) {
        final center = img.getLuminance(grayImage.getPixel(x, y)).toDouble();
        final left = img.getLuminance(grayImage.getPixel(x - 1, y)).toDouble();
        final right = img.getLuminance(grayImage.getPixel(x + 1, y)).toDouble();
        final top = img.getLuminance(grayImage.getPixel(x, y - 1)).toDouble();
        final bottom =
            img.getLuminance(grayImage.getPixel(x, y + 1)).toDouble();
        final laplacian = (4 * center) - left - right - top - bottom;
        sum += laplacian;
        sumSq += laplacian * laplacian;
        count++;
      }
    }
    if (count == 0) return 0;
    final mean = sum / count;
    final variance = (sumSq / count) - (mean * mean);
    return variance.clamp(0, double.infinity);
  }

  double _computeAverageLuminance(img.Image grayImage) {
    if (grayImage.width == 0 || grayImage.height == 0) return 0;
    double total = 0;
    for (var y = 0; y < grayImage.height; y++) {
      for (var x = 0; x < grayImage.width; x++) {
        total += img.getLuminance(grayImage.getPixel(x, y));
      }
    }
    final avg = total / (grayImage.width * grayImage.height);
    return avg.clamp(0, 255);
  }

  img.Image _applyThreshold(img.Image image) {
    final copy = image.clone();
    double total = 0;
    for (var y = 0; y < copy.height; y++) {
      for (var x = 0; x < copy.width; x++) {
        total += img.getLuminance(copy.getPixel(x, y));
      }
    }
    final mean = total / (copy.width * copy.height);
    final threshold = mean * 0.9;
    for (var y = 0; y < copy.height; y++) {
      for (var x = 0; x < copy.width; x++) {
        final lum = img.getLuminance(copy.getPixel(x, y)).toDouble();
        final value = lum >= threshold ? 255 : 0;
        img_compat.setRgba(
            copy, x, y, value.toInt(), value.toInt(), value.toInt());
      }
    }
    return copy;
  }
}
