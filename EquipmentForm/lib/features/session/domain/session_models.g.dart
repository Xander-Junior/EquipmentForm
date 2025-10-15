// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PartyFieldStateImpl _$$PartyFieldStateImplFromJson(
        Map<String, dynamic> json) =>
    _$PartyFieldStateImpl(
      value: json['value'] as String? ?? '',
      imagePath: json['imagePath'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble(),
      capturedAt: json['capturedAt'] == null
          ? null
          : DateTime.parse(json['capturedAt'] as String),
    );

Map<String, dynamic> _$$PartyFieldStateImplToJson(
        _$PartyFieldStateImpl instance) =>
    <String, dynamic>{
      'value': instance.value,
      'imagePath': instance.imagePath,
      'confidence': instance.confidence,
      'capturedAt': instance.capturedAt?.toIso8601String(),
    };

_$PartyMemberStateImpl _$$PartyMemberStateImplFromJson(
        Map<String, dynamic> json) =>
    _$PartyMemberStateImpl(
      role: $enumDecode(_$PartyRoleEnumMap, json['role']),
      fields: (json['fields'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry($enumDecode(_$PartyFieldEnumMap, k),
                PartyFieldState.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      photoPath: json['photoPath'] as String?,
      mirrorsRequested: json['mirrorsRequested'] as bool? ?? false,
    );

Map<String, dynamic> _$$PartyMemberStateImplToJson(
        _$PartyMemberStateImpl instance) =>
    <String, dynamic>{
      'role': _$PartyRoleEnumMap[instance.role]!,
      'fields':
          instance.fields.map((k, e) => MapEntry(_$PartyFieldEnumMap[k]!, e)),
      'photoPath': instance.photoPath,
      'mirrorsRequested': instance.mirrorsRequested,
    };

const _$PartyRoleEnumMap = {
  PartyRole.requestedBy: 'requestedBy',
  PartyRole.preparedBy: 'preparedBy',
  PartyRole.receivedBy: 'receivedBy',
  PartyRole.returnedBy: 'returnedBy',
};

const _$PartyFieldEnumMap = {
  PartyField.name: 'name',
  PartyField.department: 'department',
  PartyField.email: 'email',
};

_$PartySessionStateImpl _$$PartySessionStateImplFromJson(
        Map<String, dynamic> json) =>
    _$PartySessionStateImpl(
      members: (json['members'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry($enumDecode(_$PartyRoleEnumMap, k),
                PartyMemberState.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
    );

Map<String, dynamic> _$$PartySessionStateImplToJson(
        _$PartySessionStateImpl instance) =>
    <String, dynamic>{
      'members':
          instance.members.map((k, e) => MapEntry(_$PartyRoleEnumMap[k]!, e)),
    };

_$AccessoryStateImpl _$$AccessoryStateImplFromJson(Map<String, dynamic> json) =>
    _$AccessoryStateImpl(
      id: json['id'] as String,
      label: json['label'] as String,
      selected: json['selected'] as bool? ?? false,
      suggested: json['suggested'] as bool? ?? false,
    );

Map<String, dynamic> _$$AccessoryStateImplToJson(
        _$AccessoryStateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'selected': instance.selected,
      'suggested': instance.suggested,
    };

_$PrimaryDeviceStateImpl _$$PrimaryDeviceStateImplFromJson(
        Map<String, dynamic> json) =>
    _$PrimaryDeviceStateImpl(
      id: json['id'] as String,
      type: $enumDecode(_$PrimaryDeviceTypeEnumMap, json['type']),
      makeModel: _makeModelFromJson(json['makeModel']),
      assetTag: json['assetTag'] as String?,
      serviceTag: json['serviceTag'] as String?,
      serialNumber: json['serialNumber'] as String?,
      warrantyExpiry: json['warrantyExpiry'] as String?,
      imei: json['imei'] as String?,
      accessories: (json['accessories'] as List<dynamic>?)
              ?.map((e) => AccessoryState.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <AccessoryState>[],
      isReplacementOld: json['isReplacementOld'] as bool? ?? false,
    );

Map<String, dynamic> _$$PrimaryDeviceStateImplToJson(
        _$PrimaryDeviceStateImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$PrimaryDeviceTypeEnumMap[instance.type]!,
      'makeModel': _makeModelToJson(instance.makeModel),
      'assetTag': instance.assetTag,
      'serviceTag': instance.serviceTag,
      'serialNumber': instance.serialNumber,
      'warrantyExpiry': instance.warrantyExpiry,
      'imei': instance.imei,
      'accessories': instance.accessories,
      'isReplacementOld': instance.isReplacementOld,
    };

const _$PrimaryDeviceTypeEnumMap = {
  PrimaryDeviceType.laptop: 'laptop',
  PrimaryDeviceType.phone: 'phone',
};

_$EquipmentSessionStateImpl _$$EquipmentSessionStateImplFromJson(
        Map<String, dynamic> json) =>
    _$EquipmentSessionStateImpl(
      primaries: (json['primaries'] as List<dynamic>?)
              ?.map(
                  (e) => PrimaryDeviceState.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PrimaryDeviceState>[],
    );

Map<String, dynamic> _$$EquipmentSessionStateImplToJson(
        _$EquipmentSessionStateImpl instance) =>
    <String, dynamic>{
      'primaries': instance.primaries,
    };

_$WorkflowSessionStateImpl _$$WorkflowSessionStateImplFromJson(
        Map<String, dynamic> json) =>
    _$WorkflowSessionStateImpl(
      formType: $enumDecode(_$FormTypeEnumMap, json['formType']),
      location: $enumDecodeNullable(_$LocationCodeEnumMap, json['location']),
      dateReceived: json['dateReceived'] == null
          ? null
          : DateTime.parse(json['dateReceived'] as String),
      dateReturned: json['dateReturned'] == null
          ? null
          : DateTime.parse(json['dateReturned'] as String),
      dataHandlingConfirmed: json['dataHandlingConfirmed'] as bool? ?? false,
    );

Map<String, dynamic> _$$WorkflowSessionStateImplToJson(
        _$WorkflowSessionStateImpl instance) =>
    <String, dynamic>{
      'formType': _$FormTypeEnumMap[instance.formType]!,
      'location': _$LocationCodeEnumMap[instance.location],
      'dateReceived': instance.dateReceived?.toIso8601String(),
      'dateReturned': instance.dateReturned?.toIso8601String(),
      'dataHandlingConfirmed': instance.dataHandlingConfirmed,
    };

const _$FormTypeEnumMap = {
  FormType.received: 'received',
  FormType.returned: 'returned',
  FormType.replaced: 'replaced',
};

const _$LocationCodeEnumMap = {
  LocationCode.acc: 'acc',
  LocationCode.tak: 'tak',
  LocationCode.lon: 'lon',
};

_$AppSessionStateImpl _$$AppSessionStateImplFromJson(
        Map<String, dynamic> json) =>
    _$AppSessionStateImpl(
      party: PartySessionState.fromJson(json['party'] as Map<String, dynamic>),
      equipment: EquipmentSessionState.fromJson(
          json['equipment'] as Map<String, dynamic>),
      workflow: WorkflowSessionState.fromJson(
          json['workflow'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AppSessionStateImplToJson(
        _$AppSessionStateImpl instance) =>
    <String, dynamic>{
      'party': instance.party,
      'equipment': instance.equipment,
      'workflow': instance.workflow,
    };
