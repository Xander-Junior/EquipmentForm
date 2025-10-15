import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/models/session.dart';
import '../../shared/domain/normalizers.dart';

part 'session_models.freezed.dart';
part 'session_models.g.dart';

enum LocationCode { acc, tak, lon }

enum PartyRole { requestedBy, preparedBy, receivedBy, returnedBy }

enum PartyField { name, department, email }

extension PartyRoleLabel on PartyRole {
  String get label {
    switch (this) {
      case PartyRole.requestedBy:
        return 'Requested By';
      case PartyRole.preparedBy:
        return 'Prepared By';
      case PartyRole.receivedBy:
        return 'Received By';
      case PartyRole.returnedBy:
        return 'Returned By';
    }
  }
}

extension PartyFieldLabel on PartyField {
  String get label {
    switch (this) {
      case PartyField.name:
        return 'Name';
      case PartyField.department:
        return 'Department';
      case PartyField.email:
        return 'Email';
    }
  }
}

extension PrimaryDeviceDisplay on PrimaryDeviceState {
  String get displayMakeModel {
    if (type == PrimaryDeviceType.laptop) {
      final number = makeModel.trim();
      if (number.isEmpty) return 'DELL LATITUDE';
      return 'DELL LATITUDE ${number.toUpperCase()}';
    }
    return makeModel;
  }
}

extension LocationCodeLabel on LocationCode {
  String get label {
    switch (this) {
      case LocationCode.acc:
        return 'ACC';
      case LocationCode.tak:
        return 'TAK';
      case LocationCode.lon:
        return 'LON';
    }
  }
}

@freezed
class PartyFieldState with _$PartyFieldState {
  const factory PartyFieldState({
    @Default('') String value,
    String? imagePath,
    double? confidence,
    DateTime? capturedAt,
  }) = _PartyFieldState;

  factory PartyFieldState.fromJson(Map<String, dynamic> json) => _$PartyFieldStateFromJson(json);
}

@freezed
class PartyMemberState with _$PartyMemberState {
  const factory PartyMemberState({
    required PartyRole role,
    @Default({}) Map<PartyField, PartyFieldState> fields,
    String? photoPath,
    @Default(false) bool mirrorsRequested,
  }) = _PartyMemberState;

  factory PartyMemberState.fromJson(Map<String, dynamic> json) => _$PartyMemberStateFromJson(json);
}

List<PartyRole> partyRolesForForm(FormType formType) {
  switch (formType) {
    case FormType.received:
      return const [PartyRole.requestedBy, PartyRole.preparedBy, PartyRole.receivedBy];
    case FormType.returned:
      return const [PartyRole.returnedBy, PartyRole.preparedBy, PartyRole.receivedBy];
    case FormType.replaced:
      return const [PartyRole.requestedBy, PartyRole.preparedBy, PartyRole.receivedBy];
  }
}

@freezed
class PartySessionState with _$PartySessionState {
  const factory PartySessionState({
    @Default({}) Map<PartyRole, PartyMemberState> members,
  }) = _PartySessionState;

  factory PartySessionState.fromJson(Map<String, dynamic> json) => _$PartySessionStateFromJson(json);
}

enum PrimaryDeviceType { laptop, phone }

extension PrimaryDeviceLabel on PrimaryDeviceType {
  String get label => switch (this) {
        PrimaryDeviceType.laptop => 'Laptop',
        PrimaryDeviceType.phone => 'Phone',
      };

  String get deviceCode => switch (this) {
        PrimaryDeviceType.laptop => 'LT',
        PrimaryDeviceType.phone => 'MB',
      };
}

enum AccessoryKind {
  adapter,
  charger,
  bag,
  mouse,
  keyboard,
  monitor,
  dock,
  cable,
  other,
}

extension AccessoryKindLabel on AccessoryKind {
  String get label {
    switch (this) {
      case AccessoryKind.adapter:
        return 'Adapter';
      case AccessoryKind.charger:
        return 'Charger';
      case AccessoryKind.bag:
        return 'Bag';
      case AccessoryKind.mouse:
        return 'Mouse';
      case AccessoryKind.keyboard:
        return 'Keyboard';
      case AccessoryKind.monitor:
        return 'Monitor';
      case AccessoryKind.dock:
        return 'Dock';
      case AccessoryKind.cable:
        return 'Cable';
      case AccessoryKind.other:
        return 'Accessory';
    }
  }
}

@freezed
class AccessoryState with _$AccessoryState {
  const factory AccessoryState({
    required String id,
    required String label,
    @Default(false) bool selected,
    @Default(false) bool suggested,
  }) = _AccessoryState;

  factory AccessoryState.fromJson(Map<String, dynamic> json) => _$AccessoryStateFromJson(json);
}

@freezed
class PrimaryDeviceState with _$PrimaryDeviceState {
  const factory PrimaryDeviceState({
    required String id,
    required PrimaryDeviceType type,
    @JsonKey(fromJson: _makeModelFromJson, toJson: _makeModelToJson)
        required String makeModel,
    String? assetTag,
    String? serviceTag,
    String? serialNumber,
    String? warrantyExpiry,
    String? imei,
    @Default(<AccessoryState>[]) List<AccessoryState> accessories,
    @Default(false) bool isReplacementOld,
  }) = _PrimaryDeviceState;

  factory PrimaryDeviceState.fromJson(Map<String, dynamic> json) => _$PrimaryDeviceStateFromJson(json);
}

@freezed
class EquipmentSessionState with _$EquipmentSessionState {
  const factory EquipmentSessionState({
    @Default(<PrimaryDeviceState>[]) List<PrimaryDeviceState> primaries,
  }) = _EquipmentSessionState;

  factory EquipmentSessionState.fromJson(Map<String, dynamic> json) => _$EquipmentSessionStateFromJson(json);
}

@freezed
class WorkflowSessionState with _$WorkflowSessionState {
  const factory WorkflowSessionState({
    required FormType formType,
    LocationCode? location,
    DateTime? dateReceived,
    DateTime? dateReturned,
    @Default(false) bool dataHandlingConfirmed,
  }) = _WorkflowSessionState;

  factory WorkflowSessionState.fromJson(Map<String, dynamic> json) => _$WorkflowSessionStateFromJson(json);
}

@freezed
class AppSessionState with _$AppSessionState {
  const factory AppSessionState({
    required PartySessionState party,
    required EquipmentSessionState equipment,
    required WorkflowSessionState workflow,
  }) = _AppSessionState;

  factory AppSessionState.fromJson(Map<String, dynamic> json) => _$AppSessionStateFromJson(json);
}

String buildAssetTagPrefix(LocationCode location, PrimaryDeviceType type) {
  return '${location.label}-${type.deviceCode}-';
}

String _makeModelFromJson(Object? input) {
  if (input is! String) return '';
  final normalized = normalizeDellLatitudeModel(input);
  if (normalized == null) {
    return input.trim();
  }
  if (normalized.isEmpty) return '';
  return normalized.trim();
}

String _makeModelToJson(String value) => value;

String normalizeAssetTagSuffix(String input) {
  final sanitized = input.replaceAll(RegExp(r'[^0-9A-Za-z]'), '').toUpperCase();
  return sanitized;
}
