import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta/meta.dart';

import '../../../../data/models/session.dart';
import '../../controllers/session_controller.dart';
import '../../domain/session_models.dart';
import 'field_capture_sheet.dart';
import 'section_capture_wizard.dart';

class PartySessionStep extends ConsumerStatefulWidget {
  const PartySessionStep({
    super.key,
    required this.formType,
    this.sectionWizardBuilder,
  });

  final FormType formType;
  final SectionCaptureWizard Function(WidgetRef ref, FormType formType)?
      sectionWizardBuilder;

  @override
  ConsumerState<PartySessionStep> createState() => _PartySessionStepState();
}

const _tullowDomain = 'tullowoil.com';
final RegExp _tullowSuggestionPattern = RegExp(r'^[a-z]+(?:[._][a-z]+)+@$');
final RegExp _basicEmailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

@visibleForTesting
bool shouldOfferTullowDomainChip(String input) {
  final value = input.trim().toLowerCase();
  if (!value.endsWith('@')) return false;
  return _tullowSuggestionPattern.hasMatch(value);
}

@visibleForTesting
String appendTullowDomain(String input) {
  final trimmed = input.trim();
  return shouldOfferTullowDomainChip(trimmed)
      ? '${trimmed}$_tullowDomain'
      : trimmed;
}

@visibleForTesting
String? basicEmailValidationError(String input) {
  final value = input.trim();
  if (value.isEmpty || value.endsWith('@')) return null;
  return _basicEmailPattern.hasMatch(value.toLowerCase())
      ? null
      : 'Enter a valid email address';
}

class _PartySessionStepState extends ConsumerState<PartySessionStep> {
  final Map<PartyRole, Map<PartyField, TextEditingController>> _controllers =
      {};
  final Map<PartyRole, Map<PartyField, FocusNode>> _focusNodes = {};
  final Map<PartyRole, Map<PartyField, bool>> _autoSelectPending = {};
  final ImagePicker _picker = ImagePicker();
  late final ProviderSubscription<AppSessionState> _subscription;
  late SectionCaptureWizard _sectionWizard;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(sessionControllerProvider(widget.formType));
    _ensureControllers(initialState.party.members);
    _sectionWizard = widget.sectionWizardBuilder?.call(ref, widget.formType) ??
        SectionCaptureWizard(ref, widget.formType);
    _subscription = ref.listenManual<AppSessionState>(
      sessionControllerProvider(widget.formType),
      (previous, next) {
        final prevMembers = previous?.party.members ?? const {};
        final nextMembers = next.party.members;
        final structureChanged = prevMembers.length != nextMembers.length ||
            !_haveSameMemberKeys(prevMembers, nextMembers);

        if (structureChanged) {
          _ensureControllers(nextMembers);
        }

        for (final entry in nextMembers.entries) {
          final role = entry.key;
          final member = entry.value;
          for (final field in PartyField.values) {
            final value = member.fields[field]?.value ?? '';
            final controller = _controllers[role]?[field];
            if (controller != null && controller.text != value) {
              controller.text = value;
              _autoSelectPending[role]?[field] = value.trim().isNotEmpty;
            }
          }
        }
      },
    );
  }

  @override
  void didUpdateWidget(covariant PartySessionStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.formType != widget.formType) {
      _sectionWizard =
          widget.sectionWizardBuilder?.call(ref, widget.formType) ??
              SectionCaptureWizard(ref, widget.formType);
    } else if (oldWidget.sectionWizardBuilder != widget.sectionWizardBuilder) {
      _sectionWizard =
          widget.sectionWizardBuilder?.call(ref, widget.formType) ??
              SectionCaptureWizard(ref, widget.formType);
    }
  }

  bool _haveSameMemberKeys(
    Map<PartyRole, PartyMemberState> a,
    Map<PartyRole, PartyMemberState> b,
  ) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
    }
    return true;
  }

  void _ensureControllers(Map<PartyRole, PartyMemberState> members) {
    for (final entry in members.entries) {
      _controllers.putIfAbsent(entry.key, () => {});
      _focusNodes.putIfAbsent(entry.key, () => {});
      _autoSelectPending.putIfAbsent(entry.key, () => {});
      for (final field in PartyField.values) {
        _controllers[entry.key]!.putIfAbsent(field, () {
          return TextEditingController(
            text: entry.value.fields[field]?.value ?? '',
          );
        });
        _focusNodes[entry.key]!.putIfAbsent(field, () {
          final node = FocusNode();
          node.addListener(() => _handleFieldFocus(entry.key, field, node));
          return node;
        });
        final initialValue =
            _controllers[entry.key]![field]!.text.trim().isNotEmpty;
        _autoSelectPending[entry.key]![field] =
            _autoSelectPending[entry.key]![field] ?? initialValue;
      }
    }
  }

  void _handleFieldFocus(PartyRole role, PartyField field, FocusNode node) {
    final controller = _controllers[role]?[field];
    if (controller == null) return;

    if (node.hasFocus) {
      final shouldSelect = (_autoSelectPending[role]?[field] ?? false) &&
          controller.text.trim().isNotEmpty;
      if (!shouldSelect) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !node.hasFocus) return;
        controller.selection =
            TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      });
      _autoSelectPending[role]?[field] = false;
      return;
    }

    if (field != PartyField.email) return;
    final appended = appendTullowDomain(controller.text);
    if (appended == controller.text) return;
    controller.text = appended;
    _autoSelectPending[role]?[field] = false;
    ref
        .read(sessionControllerProvider(widget.formType).notifier)
        .updatePartyField(role, field, appended);
  }

  @override
  void dispose() {
    _subscription.close();
    for (final fields in _controllers.values) {
      for (final controller in fields.values) {
        controller.dispose();
      }
    }
    for (final fields in _focusNodes.values) {
      for (final node in fields.values) {
        node.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionControllerProvider(widget.formType));
    final members = state.party.members;
    if (members.isEmpty) {
      return const Center(
          child: Text('No party roles configured for this form.'));
    }

    return SafeArea(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final role = members.keys.elementAt(index);
          final member = members[role]!;
          final mirrorEligible = _isMirrorEligible(role);
          return _PartyCard(
            role: role,
            member: member,
            controllers: _controllers[role]!,
            focusNodes: _focusNodes[role]!,
            readOnly: false,
            mirrorEligible: mirrorEligible,
            onMirrorToggle: mirrorEligible
                ? (value) => _handleMirrorToggle(role, value)
                : null,
            onFieldChanged: (field, value) {
              _autoSelectPending[role]?[field] = false;
              final notifier =
                  ref.read(sessionControllerProvider(widget.formType).notifier);
              notifier.updatePartyField(role, field, value);
            },
            onCaptureField: (field) =>
                _handleFieldCapture(context, role, field),
            onCapturePhoto: () => _handlePhotoCapture(context, role),
            onSectionCapture: () => _handleSectionCapture(context, role),
          );
        },
      ),
    );
  }

  bool _isMirrorEligible(PartyRole role) {
    if (role != PartyRole.receivedBy) return false;
    return widget.formType == FormType.received ||
        widget.formType == FormType.replaced;
  }

  Future<void> _handlePhotoCapture(BuildContext context, PartyRole role) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Photo Source')),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo Library'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
    if (source == null) return;
    final pick = await _picker.pickImage(source: source, imageQuality: 90);
    if (pick == null) return;
    ref
        .read(sessionControllerProvider(widget.formType).notifier)
        .assignPartyPhoto(role, pick.path);
  }

  Future<void> _handleFieldCapture(
      BuildContext context, PartyRole role, PartyField field) async {
    final member = ref
        .read(sessionControllerProvider(widget.formType))
        .party
        .members[role];
    if (member?.mirrorsRequested == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${role.label} is linked to Requested By. Disable the toggle to edit.')),
      );
      return;
    }
    final captureField = switch (field) {
      PartyField.name => CaptureField.partyName,
      PartyField.department => CaptureField.partyDepartment,
      PartyField.email => CaptureField.partyEmail,
    };
    final sheet = FieldCaptureSheet(ref);
    final messenger = ScaffoldMessenger.of(context);
    final result = await sheet.capture(context: context, field: captureField);
    if (result == null) return;
    if (!mounted) return;
    if (result.value.isNotEmpty) {
      final controller = _controllers[role]?[field];
      controller?.text = result.value;
      _autoSelectPending[role]?[field] = result.value.trim().isNotEmpty;
      final notifier =
          ref.read(sessionControllerProvider(widget.formType).notifier);
      notifier.attachPartyFieldCapture(
        role: role,
        field: field,
        value: result.value,
        imagePath: result.imagePath,
        confidence: result.confidence,
      );
    }
    messenger.showSnackBar(
      SnackBar(
          content: Text('Capture saved for ${field.label} (${role.label}).')),
    );
  }

  Future<void> _handleSectionCapture(
      BuildContext context, PartyRole role) async {
    final messenger = ScaffoldMessenger.of(context);
    final result =
        await _sectionWizard.captureSection(context: context, role: role);
    if (!mounted || result == null) return;
    final undoValues = Map<PartyField, String>.from(result.previousValues);
    final previousMirror = result.previousMirrorsRequested;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Applied OCR results to ${role.label}.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              final notifier =
                  ref.read(sessionControllerProvider(widget.formType).notifier);
              notifier.applyPartyFields(role, undoValues);
              notifier.setMirrorFromRequested(role, previousMirror);
            },
          ),
        ),
      );
  }

  void _handleMirrorToggle(PartyRole role, bool value) {
    final notifier =
        ref.read(sessionControllerProvider(widget.formType).notifier);
    notifier.setMirrorFromRequested(role, value);
  }
}

class _PartyCard extends StatelessWidget {
  const _PartyCard({
    required this.role,
    required this.member,
    required this.controllers,
    required this.focusNodes,
    required this.readOnly,
    required this.mirrorEligible,
    this.onMirrorToggle,
    required this.onFieldChanged,
    required this.onCaptureField,
    required this.onCapturePhoto,
    required this.onSectionCapture,
  });

  final PartyRole role;
  final PartyMemberState member;
  final Map<PartyField, TextEditingController> controllers;
  final Map<PartyField, FocusNode> focusNodes;
  final bool readOnly;
  final bool mirrorEligible;
  final ValueChanged<bool>? onMirrorToggle;
  final void Function(PartyField field, String value) onFieldChanged;
  final Future<void> Function(PartyField field) onCaptureField;
  final Future<void> Function() onCapturePhoto;
  final Future<void> Function() onSectionCapture;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imagePath = member.photoPath;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 420;
                final actions = <Widget>[
                  TextButton.icon(
                    onPressed: readOnly ? null : onSectionCapture,
                    icon: const Icon(Icons.document_scanner),
                    label: const Text('Scan Section'),
                  ),
                  TextButton.icon(
                    onPressed: onCapturePhoto,
                    icon: const Icon(Icons.photo_camera_back_outlined),
                    label: const Text('Photo'),
                  ),
                ];
                final visibleActions =
                    readOnly ? actions.skip(1).toList() : actions;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: onCapturePhoto,
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: imagePath != null
                                ? FileImage(File(imagePath))
                                : null,
                            child: imagePath == null
                                ? const Icon(Icons.camera_alt)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            role.label,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (!compact) ...visibleActions,
                        if (compact)
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'scan' && !readOnly) {
                                onSectionCapture();
                              } else if (value == 'photo') {
                                onCapturePhoto();
                              }
                            },
                            itemBuilder: (context) {
                              final items = <PopupMenuEntry<String>>[];
                              if (!readOnly) {
                                items.add(const PopupMenuItem(
                                    value: 'scan',
                                    child: Text('Scan Section')));
                              }
                              items.add(const PopupMenuItem(
                                  value: 'photo',
                                  child: Text('Capture Photo')));
                              return items;
                            },
                          ),
                      ],
                    ),
                    if (compact)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Wrap(
                          spacing: 8,
                          children: visibleActions,
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            if (mirrorEligible)
              SwitchListTile.adaptive(
                key: ValueKey('mirror-${role.name}'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Same as Requested By'),
                subtitle: const Text('Stay synced with Requested By details'),
                value: member.mirrorsRequested,
                onChanged: onMirrorToggle,
              ),
            if (mirrorEligible) const SizedBox(height: 8),
            if (member.mirrorsRequested)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.link, size: 16),
                    SizedBox(width: 6),
                    Text('Linked to Requested By'),
                  ],
                ),
              ),
            for (final field in PartyField.values) ...[
              _PartyFieldRow(
                role: role,
                field: field,
                controller: controllers[field]!,
                focusNode: focusNodes[field]!,
                onChanged: (value) => onFieldChanged(field, value),
                onCapture: () => onCaptureField(field),
                readOnly: readOnly,
              ),
              if (field != PartyField.values.last) const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _PartyFieldRow extends StatefulWidget {
  const _PartyFieldRow({
    required this.role,
    required this.field,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onCapture,
    required this.readOnly,
  });

  final PartyRole role;
  final PartyField field;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final Future<void> Function() onCapture;
  final bool readOnly;

  @override
  State<_PartyFieldRow> createState() => _PartyFieldRowState();
}

class _PartyFieldRowState extends State<_PartyFieldRow> {
  bool _listening = false;
  bool _showTullowChip = false;
  String? _errorText;

  TextEditingController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _maybeAttachListener();
    if (widget.field == PartyField.email) {
      final value = _controller.text;
      _showTullowChip = !widget.readOnly && shouldOfferTullowDomainChip(value);
      _errorText = basicEmailValidationError(value);
    }
  }

  @override
  void didUpdateWidget(covariant _PartyFieldRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _maybeDetachListener(oldWidget.controller);
      _maybeAttachListener();
    }
    if (oldWidget.readOnly != widget.readOnly ||
        oldWidget.field != widget.field ||
        oldWidget.controller != widget.controller) {
      _refreshEmailState(force: true);
    }
  }

  @override
  void dispose() {
    _maybeDetachListener(_controller);
    super.dispose();
  }

  void _maybeAttachListener() {
    if (widget.field != PartyField.email || _listening) return;
    _controller.addListener(_handleControllerChange);
    _listening = true;
  }

  void _maybeDetachListener(TextEditingController controller) {
    if (!_listening) return;
    controller.removeListener(_handleControllerChange);
    _listening = false;
  }

  void _handleControllerChange() {
    _refreshEmailState();
  }

  void _refreshEmailState({bool force = false}) {
    if (widget.field != PartyField.email) return;
    final value = _controller.text;
    final shouldShowChip =
        !widget.readOnly && shouldOfferTullowDomainChip(value);
    final error = basicEmailValidationError(value);
    if (!force && shouldShowChip == _showTullowChip && error == _errorText)
      return;
    setState(() {
      _showTullowChip = shouldShowChip;
      _errorText = error;
    });
  }

  void _handleChanged(String value) {
    widget.onChanged(value);
    _refreshEmailState(force: true);
  }

  void _applyTullowDomain() {
    final updated = appendTullowDomain(_controller.text);
    if (updated == _controller.text) return;
    _controller.text = updated;
    _controller.selection = TextSelection.collapsed(offset: updated.length);
    widget.onChanged(updated);
    _refreshEmailState(force: true);
  }

  InputDecoration _decoration() {
    return InputDecoration(
      border: const OutlineInputBorder(),
      errorText: widget.field == PartyField.email ? _errorText : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.field.label,
            style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: ValueKey('party-${widget.role.name}-${widget.field.name}'),
                controller: _controller,
                focusNode: widget.focusNode,
                onChanged: _handleChanged,
                readOnly: widget.readOnly,
                decoration: _decoration(),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.crop),
                  tooltip: 'Scan field',
                  onPressed: widget.readOnly ? null : widget.onCapture,
                ),
              ],
            ),
          ],
        ),
        if (widget.field == PartyField.email && _showTullowChip)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  key: ValueKey('party-${widget.role.name}-email-domain-chip'),
                  label: const Text('tullowoil.com'),
                  onPressed: widget.readOnly ? null : _applyTullowDomain,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
