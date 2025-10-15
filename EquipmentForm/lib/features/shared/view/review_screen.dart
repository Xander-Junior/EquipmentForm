import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../data/models/session.dart';
import '../../shared/domain/device_kind.dart';
import '../../shared/domain/normalizers.dart';
import '../../shared/domain/validation.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, this.formType, this.confidence, this.extras});

  final FormType? formType;
  final double? confidence;
  final Map<String, dynamic>? extras;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final Map<String, TextEditingController> _controllers;
  final _formKey = GlobalKey<FormState>();
  final Map<String, String?> _fieldErrors = <String, String?>{};

  DeviceKind _deviceKind = DeviceKind.laptop;
  Set<String> _selectedAccessories = <String>{};

  static const List<String> _accessoryOptions = <String>[
    'Adapter',
    'Laptop Bag',
    'Mouse',
    'Keyboard',
    'USB-C Hub',
  ];

  final List<_FieldConfig> _fields = const <_FieldConfig>[
    _FieldConfig('makeModel', 'Make / Model', TextInputType.text),
    _FieldConfig('assetTag', 'Asset Tag', TextInputType.text),
    _FieldConfig('serviceTag', 'Service Tag', TextInputType.text),
    _FieldConfig('serial', 'Serial Number', TextInputType.text),
    _FieldConfig('imei', 'IMEI', TextInputType.number),
    _FieldConfig('warrantyExpiry', 'Warranty Expiry (DD/MM/YYYY)', TextInputType.datetime),
    _FieldConfig('name', 'Name', TextInputType.text),
    _FieldConfig('department', 'Department', TextInputType.text),
    _FieldConfig('email', 'Email', TextInputType.emailAddress),
  ];

  @override
  void initState() {
    super.initState();
    final extras = widget.extras ?? const {};
    final fields = Map<String, dynamic>.from(extras['fields'] as Map? ?? const {});
    _deviceKind = DeviceKind.values.tryFirstWhere((kind) => kind.name == extras['deviceKind']) ?? DeviceKind.laptop;
    _selectedAccessories = (extras['accessories'] as List?)?.cast<String>().toSet() ?? <String>{};

    _controllers = {
      for (final field in _fields)
        field.key: TextEditingController(
          text: field.key == 'warrantyExpiry'
              ? formatWarrantyExpiryForDisplay(fields[field.key]?.toString())
              : fields[field.key]?.toString() ?? '',
        ),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.formType?.name ?? 'unknown';
    final confidence = widget.confidence ?? widget.extras?['confidence'] as double?;

    return Scaffold(
      appBar: AppBar(
        title: Text('Review — ${label.toUpperCase()}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (confidence != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text('OCR Confidence: ${(confidence * 100).toStringAsFixed(1)}%'),
                ),
              DropdownButtonFormField<DeviceKind>(
                initialValue: _deviceKind,
                decoration: const InputDecoration(labelText: 'Device Kind', border: OutlineInputBorder()),
                onChanged: (value) => setState(() => _deviceKind = value ?? DeviceKind.other),
                items: DeviceKind.values
                    .map((kind) => DropdownMenuItem(value: kind, child: Text(kind.label)))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  children: _accessoryOptions
                      .map(
                        (option) => FilterChip(
                          label: Text(option),
                          selected: _selectedAccessories.contains(option),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAccessories.add(option);
                              } else {
                                _selectedAccessories.remove(option);
                              }
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _fields.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final config = _fields[index];
                    final controller = _controllers[config.key]!;
                    return TextFormField(
                      controller: controller,
                      keyboardType: config.inputType,
                      decoration: InputDecoration(
                        labelText: config.label,
                        errorText: _fieldErrors[config.key],
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) => _validateField(config.key, value),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _handleExport,
                child: const Text('Export PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateField(String field, String? value) {
    switch (field) {
      case 'name':
      case 'department':
        if (value == null || value.trim().isEmpty) {
          return 'Required field';
        }
        break;
      case 'email':
        if (value != null && value.isNotEmpty) {
          final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
          if (!emailRegex.hasMatch(value)) {
            return 'Invalid email';
          }
        }
        break;
      default:
        break;
    }
    return null;
  }

  Future<void> _handleExport() async {
    final errors = validateEquipmentFields(
      deviceKind: _deviceKind,
      makeModel: _controllers['makeModel']?.text,
      assetTag: _controllers['assetTag']?.text,
      serviceTag: _controllers['serviceTag']?.text,
      serial: _controllers['serial']?.text,
      imei: _controllers['imei']?.text,
      warrantyExpiry: _controllers['warrantyExpiry']?.text,
    );

    setState(() {
      _fieldErrors
        ..clear()
        ..addEntries(errors.map((e) => MapEntry(e.field, e.message)));
    });

    if (!_formKey.currentState!.validate() || errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please correct highlighted fields.')),
      );
      return;
    }

    final assetTagCanonical = normalizeAssetTag(_controllers['assetTag']!.text);
    final imeiCanonical = normalizeImei(_controllers['imei']!.text);
    final warrantyIso = normalizeWarrantyExpiry(_controllers['warrantyExpiry']!.text);

    final rawModel = _controllers['makeModel']!.text.trim();
    String storedModel;
    String displayModel;
    if (_deviceKind == DeviceKind.laptop) {
      final normalized = normalizeDellLatitudeModel(rawModel);
      storedModel =
          (normalized == null || normalized.isEmpty) ? rawModel.toUpperCase() : normalized.trim();
      storedModel = storedModel.toUpperCase();
      displayModel = storedModel.isEmpty
          ? 'DELL LATITUDE'
          : 'DELL LATITUDE $storedModel';
    } else {
      storedModel = rawModel;
      displayModel = rawModel;
    }

    final equipment = <String, dynamic>{
      'makeModel': storedModel,
      'assetTag': assetTagCanonical ?? _controllers['assetTag']!.text.trim(),
      'serviceTag': _controllers['serviceTag']!.text.trim(),
      'serial': _controllers['serial']!.text.trim(),
      'imei': imeiCanonical ?? _controllers['imei']!.text.trim(),
      'warrantyExpiry': warrantyIso,
      'accessories': _selectedAccessories.toList(),
    };

    final accessoryLabels = LinkedHashSet<String>.from(_selectedAccessories);
    final accessoryLine = accessoryLabels.isEmpty
        ? ''
        : ' WITH ${accessoryLabels.map((e) => e).join(accessoryLabels.length > 1 ? ' & ' : ' ')}';

    final payload = {
      'equipment': [equipment],
      'deviceKind': _deviceKind.name,
      'makeModelDisplay': '${displayModel.trim()}$accessoryLine'.trim(),
      'assetTag': equipment['assetTag'],
      'serviceTag': equipment['serviceTag'],
      'serial': equipment['serial'],
      'imei': equipment['imei'],
      'warrantyExpiry': equipment['warrantyExpiry'],
      'warrantyExpiryDisplay': formatWarrantyExpiryForDisplay(equipment['warrantyExpiry'] as String?),
      'name': _controllers['name']!.text.trim(),
      'department': _controllers['department']!.text.trim(),
      'email': _controllers['email']!.text.trim(),
      'accessories': _selectedAccessories.toList(),
    };

    context.goNamed(
      AppRoute.export.name,
      extra: {
        'formType': widget.formType ?? FormType.received,
        'fields': payload,
      },
    );
  }
}

class _FieldConfig {
  const _FieldConfig(this.key, this.label, this.inputType);
  final String key;
  final String label;
  final TextInputType inputType;
}

extension<T> on Iterable<T> {
  T? tryFirstWhere(bool Function(T element) test) {
    for (final value in this) {
      if (test(value)) return value;
    }
    return null;
  }
}
