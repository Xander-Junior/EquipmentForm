import 'package:image/image.dart' as img;

img.Image unsharp(
  img.Image source, {
  int radius = 2,
  num amount = 1.0,
  num threshold = 0,
}) {
  final original = source.clone();
  final blurred = radius > 0
      ? img.gaussianBlur(source.clone(), radius: radius)
      : source.clone();
  final result = original.clone();
  final amt = amount.toDouble();
  final thresh = threshold.toDouble();

  for (var y = 0; y < original.height; y++) {
    for (var x = 0; x < original.width; x++) {
      final origPixel = original.getPixel(x, y);
      final blurPixel = blurred.getPixel(x, y);
      final resultPixel = result.getPixel(x, y);

      num apply(num orig, num blur) {
        final diff = orig - blur;
        if (thresh > 0 && diff.abs() < thresh) {
          return orig;
        }
        return (orig + diff * amt).clamp(0, 255);
      }

      resultPixel
        ..r = apply(origPixel.r, blurPixel.r)
        ..g = apply(origPixel.g, blurPixel.g)
        ..b = apply(origPixel.b, blurPixel.b)
        ..a = origPixel.a;
    }
  }

  return result;
}

void setRgba(img.Image image, int x, int y, int r, int g, int b,
    [int a = 255]) {
  final pixel = image.getPixel(x, y);
  pixel
    ..r = r
    ..g = g
    ..b = b
    ..a = a;
}
