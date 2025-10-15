// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      name: json['name'] as String,
      department: json['department'] as String,
      email: json['email'] as String,
      defaultLocation:
          $enumDecodeNullable(_$LocationCodeEnumMap, json['defaultLocation']) ??
              LocationCode.acc,
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'department': instance.department,
      'email': instance.email,
      'defaultLocation': _$LocationCodeEnumMap[instance.defaultLocation]!,
    };

const _$LocationCodeEnumMap = {
  LocationCode.acc: 'acc',
  LocationCode.tak: 'tak',
  LocationCode.lon: 'lon',
};
