import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/session.dart';
import '../../controllers/session_controller.dart';
import '../../domain/session_models.dart';

class WorkflowSessionStep extends ConsumerWidget {
  const WorkflowSessionStep({super.key, required this.formType});

  final FormType formType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sessionControllerProvider(formType));
    final workflow = state.workflow;
    final notifier = ref.read(sessionControllerProvider(formType).notifier);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Workflow Session',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          switch (formType) {
            FormType.received =>
              'Dates default to today for received forms. Returned date stays blank.',
            FormType.returned =>
              'Date Returned defaults to today. Confirm data handling before export.',
            FormType.replaced =>
              'Control the new vs old device timeline. New device receives today; old device returns today by default.',
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<LocationCode>(
          initialValue: workflow.location ?? LocationCode.acc,
          decoration: const InputDecoration(
            labelText: 'Location / Asset Prefix',
            border: OutlineInputBorder(),
          ),
          items: LocationCode.values
              .map((code) => DropdownMenuItem(
                    value: code,
                    child: Text(code.label),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) notifier.setLocation(value);
          },
        ),
        const SizedBox(height: 16),
        switch (formType) {
          FormType.received => _DateTile(
              label: 'Date Received',
              value: workflow.dateReceived,
              onChanged: notifier.setDateReceived,
            ),
          FormType.returned => _DateTile(
              label: 'Date Returned',
              value: workflow.dateReturned,
              onChanged: notifier.setDateReturned,
            ),
          FormType.replaced => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateTile(
                  label: 'New Device — Date Received',
                  value: workflow.dateReceived,
                  onChanged: notifier.setDateReceived,
                ),
                const SizedBox(height: 12),
                _DateTile(
                  label: 'Old Device — Date Returned',
                  value: workflow.dateReturned,
                  onChanged: notifier.setDateReturned,
                ),
              ],
            ),
        },
        if (formType == FormType.returned || formType == FormType.replaced) ...[
          const SizedBox(height: 16),
          CheckboxListTile(
            value: workflow.dataHandlingConfirmed,
            onChanged: (value) => notifier.setDataHandling(value ?? false),
            title: const Text('Data handling complete'),
            subtitle: const Text(
                'OneDrive backup captured and personal data removed'),
          ),
        ],
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile(
      {required this.label, required this.value, required this.onChanged});

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: theme.textTheme.labelLarge),
      subtitle: Text(value == null ? 'Blank by design' : _format(value!)),
      trailing: OutlinedButton.icon(
        icon: const Icon(Icons.calendar_month),
        label: const Text('Select'),
        onPressed: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? now,
            firstDate: DateTime(now.year - 5),
            lastDate: DateTime(now.year + 5),
          );
          if (picked != null) {
            final withTime = DateTime(
                picked.year, picked.month, picked.day, now.hour, now.minute);
            onChanged(withTime);
          }
        },
      ),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 5),
        );
        if (picked != null) {
          final withTime = DateTime(
              picked.year, picked.month, picked.day, now.hour, now.minute);
          onChanged(withTime);
        }
      },
    );
  }

  String _format(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
