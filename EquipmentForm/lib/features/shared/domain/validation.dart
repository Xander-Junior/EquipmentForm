import 'device_kind.dart';
import 'normalizers.dart';

class FieldError {
  FieldError(this.field, this.message);
  final String field;
  final String message;
}

List<FieldError> validateEquipmentFields({
  required DeviceKind deviceKind,
  required String? makeModel,
  required String? assetTag,
  required String? serviceTag,
  String? serial,
  String? imei,
  String? warrantyExpiry,
}) {
  final errors = <FieldError>[];

  if (makeModel == null || makeModel.trim().isEmpty) {
    errors.add(FieldError('makeModel', 'Device name is required'));
  }

  String? assetError;
  if (deviceKind == DeviceKind.other) {
    if (assetTag != null && assetTag.trim().isNotEmpty) {
      assetError = validateAssetTag(assetTag);
    }
  } else {
    assetError = validateAssetTag(assetTag);
  }
  if (assetError != null) {
    errors.add(FieldError('assetTag', assetError));
  }

  if (deviceKind == DeviceKind.laptop || deviceKind == DeviceKind.desktop) {
    if (serviceTag == null || serviceTag.trim().isEmpty) {
      errors.add(FieldError('serviceTag', 'Service tag is required for this device'));
    }
  }

  if (deviceKind == DeviceKind.phone || deviceKind == DeviceKind.tablet) {
    final imeiError = validateImei(imei);
    if (imeiError != null) {
      errors.add(FieldError('imei', imeiError));
    }
  }

  final weError = validateWarrantyExpiry(warrantyExpiry);
  if (weError != null) {
    errors.add(FieldError('warrantyExpiry', weError));
  }

  return errors;
}
