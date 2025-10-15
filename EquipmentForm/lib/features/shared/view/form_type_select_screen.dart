import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../data/models/session.dart';

class FormTypeSelectScreen extends StatelessWidget {
  const FormTypeSelectScreen({super.key});

  static const List<FormType> _options = FormType.values;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Form Type')),
      body: ListView.builder(
        itemCount: _options.length,
        itemBuilder: (context, index) {
          final option = _options[index];
          return ListTile(
            title: Text(option.name.toUpperCase()),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => context.goNamed(
              AppRoute.session.name,
              extra: option,
            ),
          );
        },
      ),
    );
  }
}
