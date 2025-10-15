import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../data/models/session.dart';

class ProfileCaptureScreen extends StatelessWidget {
  const ProfileCaptureScreen({super.key, this.formType});

  final FormType? formType;

  @override
  Widget build(BuildContext context) {
    final label = formType?.name ?? 'unknown';
    return Scaffold(
      appBar: AppBar(title: Text('Profile Capture — ${label.toUpperCase()}')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.goNamed(
            AppRoute.deviceCapture.name,
            extra: formType,
          ),
          child: const Text('Continue to Device Capture'),
        ),
      ),
    );
  }
}
