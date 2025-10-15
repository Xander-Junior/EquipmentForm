import 'package:freezed_annotation/freezed_annotation.dart';

import '../../session/domain/session_models.dart';

part 'user_profile.freezed.dart';
part 'user_profile.g.dart';

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String name,
    required String department,
    required String email,
    @Default(LocationCode.acc) LocationCode defaultLocation,
  }) = _UserProfile;

  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
}

const demoUserProfile = UserProfile(
  name: 'Prepared User',
  department: 'Digital',
  email: 'prepared.user@tullowoil.com',
  defaultLocation: LocationCode.acc,
);
