import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipment Forms')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.goNamed(AppRoute.formTypeSelect.name),
          child: const Text('Start New Session'),
        ),
      ),
    );
  }
}
