import 'dart:collection';

import 'package:flutter/material.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/equipment_model/label.dart';
import '../../../../data/models/session.dart';
import '../../domain/session_models.dart';

String _formatAccessoryLabel(String label) {
  final cleaned = label.trim();
  final normalized =
      cleaned.toUpperCase().replaceFirst(RegExp(r'^WITH\s+'), '');
  if (normalized.isEmpty) return 'WITH';
  return 'WITH $normalized';
}

class EquipmentRowSimulator extends StatelessWidget {
  const EquipmentRowSimulator({
    super.key,
    required this.devices,
    required this.formType,
    required this.workflow,
    this.labelResolver,
  });

  final List<PrimaryDeviceState> devices;
  final FormType formType;
  final WorkflowSessionState workflow;
  final EquipmentLabel Function(PrimaryDeviceState device)? labelResolver;

  @override
  Widget build(BuildContext context) {
    if (devices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Row Simulator',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Primary devices render as rows with accessories inline. Preview updates as you edit.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                },
                border: TableBorder.all(color: Theme.of(context).dividerColor),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Equipment Make / Model',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Equipment Serial / Details',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...devices.map(_buildRow),
                ],
              ),
              const SizedBox(height: 12),
              _WorkflowSummary(formType: formType, workflow: workflow),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildRow(PrimaryDeviceState device) {
    final accessories = device.accessories.where((acc) => acc.selected);
    final accessoryLines = LinkedHashSet<String>.from(
      accessories.map((acc) => _formatAccessoryLabel(acc.label)),
    ).toList();
    final label = labelResolver?.call(device) ??
        readLabelFromJson(Map<String, dynamic>.from(device.toJson()));
    final display = FeatureFlags.normalizedEquipmentModel && label.isStructured
        ? label.toDisplayUpper()
        : device.displayMakeModel;
    final leftLines = [display, ...accessoryLines];

    final rightLines = <String>[];
    if (device.type == PrimaryDeviceType.laptop) {
      if ((device.assetTag ?? '').isNotEmpty)
        rightLines.add('ASSET-TAG: ${device.assetTag}');
      if ((device.serviceTag ?? '').isNotEmpty)
        rightLines.add('SERVICE TAG: ${device.serviceTag}');
      if ((device.warrantyExpiry ?? '').isNotEmpty)
        rightLines.add('W.E.: ${device.warrantyExpiry}');
    } else {
      if ((device.imei ?? '').isNotEmpty)
        rightLines.add('IMEI: ${device.imei}');
      if ((device.serialNumber ?? '').isNotEmpty)
        rightLines.add('SERIAL: ${device.serialNumber}');
      if ((device.assetTag ?? '').isNotEmpty)
        rightLines.add('ASSET-TAG: ${device.assetTag}');
    }

    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
              leftLines.where((line) => line.trim().isNotEmpty).join('\n')),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(rightLines.isEmpty ? '—' : rightLines.join('\n')),
        ),
      ],
    );
  }
}

class _WorkflowSummary extends StatelessWidget {
  const _WorkflowSummary({required this.formType, required this.workflow});

  final FormType formType;
  final WorkflowSessionState workflow;

  @override
  Widget build(BuildContext context) {
    final items = <String>[];
    if (workflow.location != null) {
      items.add('Location: ${workflow.location!.label}');
    }
    switch (formType) {
      case FormType.received:
        if (workflow.dateReceived != null) {
          items.add('Date Received: ${_format(workflow.dateReceived!)}');
        }
        break;
      case FormType.returned:
        if (workflow.dateReturned != null) {
          items.add('Date Returned: ${_format(workflow.dateReturned!)}');
        }
        items.add(
            'Data handling confirmed: ${workflow.dataHandlingConfirmed ? 'Yes' : 'No'}');
        break;
      case FormType.replaced:
        if (workflow.dateReceived != null) {
          items.add('New device received: ${_format(workflow.dateReceived!)}');
        }
        if (workflow.dateReturned != null) {
          items.add('Old device returned: ${_format(workflow.dateReturned!)}');
        }
        items.add(
            'Data handling confirmed: ${workflow.dataHandlingConfirmed ? 'Yes' : 'No'}');
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Workflow Summary', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(items.isEmpty ? 'No workflow data yet' : items.join(' • ')),
      ],
    );
  }

  String _format(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
