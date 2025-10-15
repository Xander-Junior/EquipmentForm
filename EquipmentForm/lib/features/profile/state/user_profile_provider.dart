import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/user_profile.dart';

final currentUserProfileProvider = Provider<UserProfile>((ref) {
  // Placeholder until hooked to real auth profile.
  return demoUserProfile;
});
