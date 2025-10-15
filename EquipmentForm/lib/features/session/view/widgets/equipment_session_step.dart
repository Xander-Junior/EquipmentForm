import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/equipment_model/label.dart';
import '../../../../data/models/session.dart';
import '../../controllers/session_controller.dart';
import '../../domain/session_models.dart';
import '../../../shared/domain/normalizers.dart';
import '../../../shared/widgets/input_formatters.dart';
import 'equipment_header_title.dart';
import 'equipment_row_simulator.dart';
import 'field_capture_sheet.dart';

class EquipmentSessionStep extends ConsumerStatefulWidget {
  const EquipmentSessionStep({
    super.key,
    required this.formType,
    this.labelResolver,
  });

  final FormType formType;
  final EquipmentLabel Function(PrimaryDeviceState device)? labelResolver;

  @override
  ConsumerState<EquipmentSessionStep> createState() =>
      _EquipmentSessionStepState();
}

String formatImei(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && i % 4 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

class _EquipmentSessionStepState extends ConsumerState<EquipmentSessionStep> {
  final Map<String, _DeviceControllers> _controllers = HashMap();
  late final ProviderSubscription<AppSessionState> _subscription;
  final List<String> _phoneModels = const [
    'iPhone 11',
    'iPhone 11 Pro',
    'iPhone 12',
    'iPhone 12 Pro',
    'iPhone 13',
    'iPhone 13 Pro',
    'iPhone 14',
    'iPhone 14 Pro',
    'iPhone 15',
    'iPhone 15 Pro',
  ];

  @override
  void initState() {
    super.initState();
    final initial = ref.read(sessionControllerProvider(widget.formType));
    _ensureControllers(initial.equipment.primaries);
    _subscription = ref.listenManual<AppSessionState>(
      sessionControllerProvider(widget.formType),
      (previous, next) {
        _ensureControllers(next.equipment.primaries);
        for (final device in next.equipment.primaries) {
          _controllers[device.id]?.sync(device);
        }
      },
    );
  }

  void _ensureControllers(List<PrimaryDeviceState> devices) {
    for (final device in devices) {
      _controllers.putIfAbsent(device.id, () => _DeviceControllers(device));
    }
    final existingIds = _controllers.keys.toSet();
    for (final id in existingIds) {
      if (devices.every((device) => device.id != id)) {
        _controllers.remove(id)?.dispose();
      }
    }
  }

  @override
  void dispose() {
    _subscription.close();
    for (final entry in _controllers.values) {
      entry.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionControllerProvider(widget.formType));
    final devices = state.equipment.primaries;
    final notifier =
        ref.read(sessionControllerProvider(widget.formType).notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  notifier.addPrimaryDevice(PrimaryDeviceType.laptop);
                }),
                icon: const Icon(Icons.laptop_mac),
                label: const Text('Add Laptop'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  notifier.addPrimaryDevice(PrimaryDeviceType.phone);
                }),
                icon: const Icon(Icons.smartphone),
                label: const Text('Add Phone'),
              ),
            ],
          ),
        ),
        if (devices.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
                'Add at least one laptop or phone. Accessories will attach to the most recent device.'),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                final controllers = _controllers[device.id]!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _DeviceEditorCard(
                    formType: widget.formType,
                    device: device,
                    controllers: controllers,
                    phoneModels: _phoneModels,
                    labelResolver: widget.labelResolver,
                  ),
                );
              },
            ),
          ),
        EquipmentRowSimulator(
          devices: devices,
          formType: widget.formType,
          workflow: state.workflow,
          labelResolver: widget.labelResolver,
        ),
      ],
    );
  }
}

class _DeviceEditorCard extends ConsumerWidget {
  const _DeviceEditorCard({
    required this.formType,
    required this.device,
    required this.controllers,
    required this.phoneModels,
    this.labelResolver,
  });

  final FormType formType;
  final PrimaryDeviceState device;
  final _DeviceControllers controllers;
  final List<String> phoneModels;
  final EquipmentLabel Function(PrimaryDeviceState device)? labelResolver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(sessionControllerProvider(formType).notifier);
    final prefix = notifier.prefixFor(device.type);
    final capture = FieldCaptureSheet(ref);
    final structuredLabel = labelResolver?.call(device) ??
        readLabelFromJson(Map<String, dynamic>.from(device.toJson()));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(device.type == PrimaryDeviceType.laptop
                    ? Icons.laptop
                    : Icons.smartphone),
                const SizedBox(width: 12),
                EquipmentHeaderTitle(
                  type: device.type,
                  fallbackLabel: controllers.displayLabel,
                  structuredLabel: structuredLabel,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => notifier.removePrimaryDevice(device.id),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove device',
                ),
              ],
            ),
            if (formType == FormType.replaced) ...[
              const SizedBox(height: 8),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment<bool>(value: false, label: Text('NEW')),
                  ButtonSegment<bool>(value: true, label: Text('OLD')),
                ],
                selected: {device.isReplacementOld},
                multiSelectionEnabled: false,
                onSelectionChanged: (values) {
                  final isOld = values.contains(true);
                  notifier.setReplacementPhase(
                      primaryId: device.id, isOld: isOld);
                },
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            if (device.type == PrimaryDeviceType.phone)
              DropdownButtonFormField<String>(
                initialValue: controllers.phoneModel,
                decoration: const InputDecoration(
                  labelText: 'Phone Model',
                  border: OutlineInputBorder(),
                ),
                items: phoneModels
                    .map(
                      (model) => DropdownMenuItem<String>(
                        value: model,
                        child: Text(model),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  controllers.phoneModel = value;
                  notifier.updatePrimaryDevice(device.id,
                      (current) => current.copyWith(makeModel: value ?? ''));
                },
              ),
            if (device.type == PrimaryDeviceType.phone)
              const SizedBox(height: 12),
            if (device.type == PrimaryDeviceType.laptop)
              _LaptopModelRow(
                controller: controllers.makeModel,
                onChanged: (value) {
                  final normalized = value.trim().toUpperCase();
                  notifier.updatePrimaryDevice(
                    device.id,
                    (current) => current.copyWith(makeModel: normalized),
                  );
                },
                onCapture: () async {
                  final result = await capture.capture(
                      context: context, field: CaptureField.makeModel);
                  if (result == null) return;
                  final normalized =
                      normalizeDellLatitudeModel(result.value) ?? result.value;
                  controllers.makeModel.text = normalized.trim().toUpperCase();
                  notifier.updatePrimaryDevice(
                    device.id,
                    (current) => current.copyWith(
                      makeModel: controllers.makeModel.text.trim(),
                    ),
                  );
                },
              )
            else
              _ReadOnlyField(
                  label: 'Make / Model',
                  value: device.makeModel.isEmpty
                      ? controllers.phoneModel ?? ''
                      : device.makeModel),
            if (device.type == PrimaryDeviceType.laptop)
              const SizedBox(height: 12),
            if (device.type == PrimaryDeviceType.laptop)
              _DeviceFieldRow(
                label: 'Asset Tag',
                prefixText: prefix,
                controller: controllers.assetTag,
                formatter: UppercaseFormatter(),
                onChanged: (value) => notifier.updatePrimaryDevice(
                    device.id,
                    (current) =>
                        current.copyWith(assetTag: prefix + value.trim())),
                onCapture: () async {
                  final result = await capture.capture(
                      context: context, field: CaptureField.assetTag);
                  if (result == null) return;
                  final normalized = result.value.replaceFirst(prefix, '');
                  controllers.assetTag.text = normalized;
                  notifier.updatePrimaryDevice(
                      device.id,
                      (current) =>
                          current.copyWith(assetTag: prefix + normalized));
                },
              )
            else
              _DeviceFieldRow(
                label: 'Asset Tag (optional)',
                prefixText: prefix,
                controller: controllers.assetTag,
                formatter: UppercaseFormatter(),
                onChanged: (value) => notifier.updatePrimaryDevice(
                    device.id,
                    (current) => current.copyWith(
                        assetTag:
                            value.isEmpty ? null : prefix + value.trim())),
                onCapture: () async {
                  final result = await capture.capture(
                      context: context, field: CaptureField.assetTag);
                  if (result == null) return;
                  final normalized = result.value.replaceFirst(prefix, '');
                  controllers.assetTag.text = normalized;
                  notifier.updatePrimaryDevice(
                      device.id,
                      (current) =>
                          current.copyWith(assetTag: prefix + normalized));
                },
              ),
            const SizedBox(height: 12),
            if (device.type == PrimaryDeviceType.laptop)
              _DeviceFieldRow(
                label: 'Service Tag',
                controller: controllers.serviceTag,
                formatter: UppercaseFormatter(),
                onChanged: (value) => notifier.updatePrimaryDevice(device.id,
                    (current) => current.copyWith(serviceTag: value)),
                onCapture: () async {
                  final result = await capture.capture(
                      context: context, field: CaptureField.serviceTag);
                  if (result == null) return;
                  controllers.serviceTag.text = result.value;
                  notifier.updatePrimaryDevice(device.id,
                      (current) => current.copyWith(serviceTag: result.value));
                },
              ),
            if (device.type == PrimaryDeviceType.phone) ...[
              const SizedBox(height: 12),
              _DeviceFieldRow(
                label: 'Serial Number (optional)',
                controller: controllers.serialNumber,
                formatter: UppercaseFormatter(),
                onChanged: (value) => notifier.updatePrimaryDevice(
                    device.id,
                    (current) => current.copyWith(
                        serialNumber: value.isEmpty ? null : value)),
                onCapture: () async {
                  final result = await capture.capture(
                      context: context, field: CaptureField.serialNumber);
                  if (result == null) return;
                  controllers.serialNumber.text = result.value;
                  notifier.updatePrimaryDevice(
                      device.id,
                      (current) =>
                          current.copyWith(serialNumber: result.value));
                },
              ),
              const SizedBox(height: 12),
              _DeviceFieldRow(
                label: 'IMEI',
                controller: controllers.imei,
                keyboardType: TextInputType.number,
                formatter: IMEIFormatter(),
                helperText: _imeiHelper(controllers.imei.text),
                onChanged: (value) {
                  final canonical = value.replaceAll(' ', '');
                  notifier.updatePrimaryDevice(device.id,
                      (current) => current.copyWith(imei: canonical));
                },
                onCapture: () async {
                  final result = await capture.capture(
                      context: context, field: CaptureField.imei);
                  if (result == null) return;
                  controllers.imei.text = formatImei(result.value);
                  notifier.updatePrimaryDevice(device.id,
                      (current) => current.copyWith(imei: result.value));
                },
              ),
            ],
            const SizedBox(height: 12),
            if (device.type == PrimaryDeviceType.laptop)
              _DeviceFieldRow(
                label: 'Warranty Expiry (DD/MM/YYYY)',
                controller: controllers.warranty,
                keyboardType: TextInputType.datetime,
                onChanged: (value) => notifier.updatePrimaryDevice(
                    device.id,
                    (current) => current.copyWith(
                        warrantyExpiry: value.isEmpty ? null : value)),
                onCapture: () async {
                  final result = await capture.capture(
                      context: context, field: CaptureField.warrantyExpiry);
                  if (result == null) return;
                  controllers.warranty.text = result.value;
                  notifier.updatePrimaryDevice(
                      device.id,
                      (current) =>
                          current.copyWith(warrantyExpiry: result.value));
                },
              ),
            const SizedBox(height: 16),
            _AccessoryGrid(
              device: device,
              onToggle: (accessoryId, selected) => notifier.toggleAccessory(
                primaryId: device.id,
                accessoryId: accessoryId,
                selected: selected,
              ),
              onAddCustom: (label) => notifier.addCustomAccessory(
                  primaryId: device.id, label: label),
              onRemove: (accessoryId) => notifier.removeAccessory(
                  primaryId: device.id, accessoryId: accessoryId),
            ),
          ],
        ),
      ),
    );
  }

  String? _imeiHelper(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    final groups = <String>[];
    for (var i = 0; i < digits.length; i += 4) {
      groups.add(digits.substring(i, min(i + 4, digits.length)));
    }
    return groups.join(' ');
  }
}

class _DeviceControllers {
  _DeviceControllers(PrimaryDeviceState device)
      : isLaptop = device.type == PrimaryDeviceType.laptop,
        makeModel = TextEditingController(
          text: device.type == PrimaryDeviceType.laptop
              ? _extractLaptopModelNumber(device.makeModel)
              : device.makeModel,
        ),
        assetTag = TextEditingController(
            text: device.assetTag != null
                ? device.assetTag!.split('-').skip(2).join('-')
                : ''),
        serviceTag = TextEditingController(text: device.serviceTag ?? ''),
        serialNumber = TextEditingController(text: device.serialNumber ?? ''),
        warranty = TextEditingController(text: device.warrantyExpiry ?? ''),
        imei = TextEditingController(text: device.imei ?? ''),
        phoneModel = device.type == PrimaryDeviceType.phone &&
                device.makeModel.isNotEmpty
            ? device.makeModel
            : null;

  final bool isLaptop;
  final TextEditingController makeModel;
  final TextEditingController assetTag;
  final TextEditingController serviceTag;
  final TextEditingController serialNumber;
  final TextEditingController warranty;
  final TextEditingController imei;
  String? phoneModel;

  String get displayLabel => isLaptop
      ? _formattedLaptopLabel(makeModel.text)
      : (makeModel.text.isNotEmpty ? makeModel.text : (phoneModel ?? ''));

  void sync(PrimaryDeviceState device) {
    if (device.type == PrimaryDeviceType.phone && device.makeModel.isNotEmpty) {
      phoneModel = device.makeModel;
    }
    final targetModel = device.type == PrimaryDeviceType.laptop
        ? _extractLaptopModelNumber(device.makeModel)
        : device.makeModel;
    if (makeModel.text != targetModel) {
      makeModel.text = targetModel;
    }
    final cleanedAsset = device.assetTag ?? '';
    if (cleanedAsset.isNotEmpty) {
      final suffix = cleanedAsset.split('-').skip(2).join('-');
      if (assetTag.text != suffix) {
        assetTag.text = suffix;
      }
    } else if (assetTag.text.isNotEmpty) {
      assetTag.clear();
    }
    if (serviceTag.text != (device.serviceTag ?? '')) {
      serviceTag.text = device.serviceTag ?? '';
    }
    if (serialNumber.text != (device.serialNumber ?? '')) {
      serialNumber.text = device.serialNumber ?? '';
    }
    if (warranty.text != (device.warrantyExpiry ?? '')) {
      warranty.text = device.warrantyExpiry ?? '';
    }
    if (imei.text.replaceAll(' ', '') !=
        (device.imei ?? '').replaceAll(' ', '')) {
      imei.text = formatImei(device.imei ?? '');
    }
  }

  void dispose() {
    makeModel.dispose();
    assetTag.dispose();
    serviceTag.dispose();
    serialNumber.dispose();
    warranty.dispose();
    imei.dispose();
  }
}

String _extractLaptopModelNumber(String value) {
  final normalized = normalizeDellLatitudeModel(value);
  if (normalized == null) return value;
  if (normalized.isEmpty) return '';
  return normalized;
}

String _formattedLaptopLabel(String rawNumber) {
  final number = rawNumber.trim();
  if (number.isEmpty) return 'DELL LATITUDE';
  return 'DELL LATITUDE ${number.toUpperCase()}';
}

class _DeviceFieldRow extends StatefulWidget {
  const _DeviceFieldRow({
    required this.label,
    required this.controller,
    required this.onChanged,
    required this.onCapture,
    this.prefixText,
    this.keyboardType,
    this.helperText,
    this.formatter,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onCapture;
  final String? prefixText;
  final TextInputType? keyboardType;
  final String? helperText;
  final TextInputFormatter? formatter;

  @override
  State<_DeviceFieldRow> createState() => _DeviceFieldRowState();
}

class _DeviceFieldRowState extends State<_DeviceFieldRow> {
  late final FocusNode _focusNode;
  bool _shouldSelectAll = false;
  bool _hasEdited = false;
  String _lastValue = '';

  TextEditingController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _controller.addListener(_handleControllerChange);
    _lastValue = _controller.text;
    _shouldSelectAll = _controller.text.trim().isNotEmpty;
  }

  @override
  void didUpdateWidget(covariant _DeviceFieldRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChange);
      _controller.addListener(_handleControllerChange);
      _lastValue = _controller.text;
      _shouldSelectAll = _controller.text.trim().isNotEmpty;
      _hasEdited = false;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _controller.removeListener(_handleControllerChange);
    super.dispose();
  }

  void _handleControllerChange() {
    final current = _controller.text;
    if (current != _lastValue && !_focusNode.hasFocus) {
      _hasEdited = false;
      _shouldSelectAll = current.trim().isNotEmpty;
    }
    _lastValue = current;
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) return;
    if (_hasEdited || !_shouldSelectAll) return;
    final text = _controller.text;
    if (text.isEmpty) {
      _shouldSelectAll = false;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_focusNode.hasFocus) return;
      _controller.selection =
          TextSelection(baseOffset: 0, extentOffset: text.length);
    });
    _shouldSelectAll = false;
  }

  void _handleChanged(String value) {
    _hasEdited = true;
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: widget.keyboardType,
                inputFormatters: [
                  if (widget.formatter != null) widget.formatter!,
                ],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  prefixText: widget.prefixText,
                  helperText: widget.helperText,
                ),
                onChanged: _handleChanged,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.crop),
              onPressed: widget.onCapture,
            ),
          ],
        ),
      ],
    );
  }
}

class _LaptopModelRow extends StatelessWidget {
  const _LaptopModelRow({
    required this.controller,
    required this.onChanged,
    required this.onCapture,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onCapture;

  static const _prefixLabel = 'DELL·LATITUDE';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Make / Model', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            const Chip(
              label: Text(_prefixLabel),
              avatar: Icon(Icons.laptop, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: const [UppercaseFormatter()],
                decoration: const InputDecoration(
                  hintText: 'Model number',
                  border: OutlineInputBorder(),
                ),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: onCapture,
              icon: const Icon(Icons.camera_alt),
              tooltip: 'Scan model',
            ),
          ],
        ),
      ],
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(value.isEmpty ? '—' : value),
        ),
      ],
    );
  }
}

class _AccessoryGrid extends StatelessWidget {
  const _AccessoryGrid({
    required this.device,
    required this.onToggle,
    required this.onAddCustom,
    required this.onRemove,
  });

  final PrimaryDeviceState device;
  final void Function(String accessoryId, bool selected) onToggle;
  final void Function(String label) onAddCustom;
  final void Function(String accessoryId) onRemove;

  @override
  Widget build(BuildContext context) {
    final accessories = device.accessories;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Accessories', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: accessories
              .map(
                (accessory) => FilterChip(
                  label: Text(accessory.label.toUpperCase()),
                  selected: accessory.selected,
                  onSelected: (value) => onToggle(accessory.id, value),
                  avatar: accessory.suggested
                      ? const Icon(Icons.lightbulb_outline, size: 16)
                      : accessory.selected
                          ? const Icon(Icons.check, size: 16)
                          : null,
                  deleteIcon: accessory.suggested
                      ? null
                      : const Icon(Icons.close, size: 16),
                  onDeleted:
                      accessory.suggested ? null : () => onRemove(accessory.id),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        _AccessoryAddField(onAdd: onAddCustom),
      ],
    );
  }
}

class _AccessoryAddField extends StatefulWidget {
  const _AccessoryAddField({required this.onAdd});

  final void Function(String label) onAdd;

  @override
  State<_AccessoryAddField> createState() => _AccessoryAddFieldState();
}

class _AccessoryAddFieldState extends State<_AccessoryAddField> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Add accessory line',
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            final label = _controller.text.trim();
            if (label.isEmpty) return;
            widget.onAdd(label);
            _controller.clear();
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class IMEIFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = formatImei(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
