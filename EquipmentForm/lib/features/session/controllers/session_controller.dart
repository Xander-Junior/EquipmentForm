import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/session.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/state/user_profile_provider.dart';
import '../domain/session_models.dart';
import '../../shared/domain/normalizers.dart';

class SessionController extends StateNotifier<AppSessionState> {
  SessionController({
    required FormType formType,
    required UserProfile currentUser,
  })  : _currentUser = currentUser,
        _initialState = _buildInitialState(formType, currentUser),
        super(_buildInitialState(formType, currentUser));

  final UserProfile _currentUser;
  final AppSessionState _initialState;
  bool _isDirty = false;
  final Map<PartyRole, Set<PartyRole>> _mirrorGraph = {};

  bool get isDirty => _isDirty;

  static AppSessionState _buildInitialState(
    FormType formType,
    UserProfile currentUser,
  ) {
    return AppSessionState(
      party: _initialPartyState(formType: formType, currentUser: currentUser),
      equipment: const EquipmentSessionState(),
      workflow: _initialWorkflowState(
        formType: formType,
        location: currentUser.defaultLocation,
      ),
    );
  }

  static PartySessionState _initialPartyState({
    required FormType formType,
    required UserProfile currentUser,
  }) {
    final roles = partyRolesForForm(formType);
    final members = <PartyRole, PartyMemberState>{};
    for (final role in roles) {
      final baseFields = {
        for (final field in PartyField.values) field: const PartyFieldState(),
      };
      if (role == PartyRole.preparedBy) {
        baseFields[PartyField.name] = PartyFieldState(value: currentUser.name);
        baseFields[PartyField.department] =
            PartyFieldState(value: currentUser.department);
        baseFields[PartyField.email] =
            PartyFieldState(value: currentUser.email);
      } else if (role == PartyRole.receivedBy &&
          (formType == FormType.returned || formType == FormType.replaced)) {
        baseFields[PartyField.name] = PartyFieldState(value: currentUser.name);
        baseFields[PartyField.department] =
            PartyFieldState(value: currentUser.department);
        baseFields[PartyField.email] =
            PartyFieldState(value: currentUser.email);
      }
      members[role] = PartyMemberState(role: role, fields: baseFields);
    }
    return PartySessionState(members: members);
  }

  static WorkflowSessionState _initialWorkflowState({
    required FormType formType,
    required LocationCode location,
  }) {
    final today = DateTime.now();
    switch (formType) {
      case FormType.received:
        return WorkflowSessionState(
          formType: formType,
          location: location,
          dateReceived: today,
          dateReturned: null,
          dataHandlingConfirmed: false,
        );
      case FormType.returned:
        return WorkflowSessionState(
          formType: formType,
          location: location,
          dateReceived: null,
          dateReturned: today,
          dataHandlingConfirmed: false,
        );
      case FormType.replaced:
        return WorkflowSessionState(
          formType: formType,
          location: location,
          dateReceived: today,
          dateReturned: today,
          dataHandlingConfirmed: false,
        );
    }
  }

  void updatePartyField(PartyRole role, PartyField field, String value) {
    final member = state.party.members[role];
    if (member == null) return;
    final updatedField = member.fields[field]?.copyWith(value: value) ??
        PartyFieldState(value: value);
    final updatedMember = member.copyWith(fields: {
      ...member.fields,
      field: updatedField,
    });
    final members = Map<PartyRole, PartyMemberState>.from(state.party.members);
    members[role] = updatedMember;
    _propagateMirrorValue(members, role, field, updatedField.value);
    _emit(
      state.copyWith(
        party: state.party.copyWith(members: members),
      ),
    );
  }

  void attachPartyFieldCapture({
    required PartyRole role,
    required PartyField field,
    required String value,
    String? imagePath,
    double? confidence,
  }) {
    final member = state.party.members[role];
    if (member == null) return;
    final newField = (member.fields[field] ?? const PartyFieldState()).copyWith(
      value: value,
      imagePath: imagePath,
      confidence: confidence,
      capturedAt: DateTime.now(),
    );
    final updatedMember = member.copyWith(fields: {
      ...member.fields,
      field: newField,
    });
    final members = Map<PartyRole, PartyMemberState>.from(state.party.members);
    members[role] = updatedMember;
    _propagateMirrorValue(members, role, field, newField.value);
    _emit(
      state.copyWith(
        party: state.party.copyWith(members: members),
      ),
    );
  }

  void assignPartyPhoto(PartyRole role, String? imagePath) {
    final member = state.party.members[role];
    if (member == null) return;
    final updatedMember = member.copyWith(photoPath: imagePath);
    _emit(
      state.copyWith(
        party: state.party.copyWith(
          members: {
            ...state.party.members,
            role: updatedMember,
          },
        ),
      ),
    );
  }

  void applyPartyFields(PartyRole role, Map<PartyField, String> values) {
    final member = state.party.members[role];
    if (member == null) return;
    final updatedFields = Map<PartyField, PartyFieldState>.from(member.fields);
    values.forEach((key, value) {
      updatedFields[key] =
          (updatedFields[key] ?? const PartyFieldState()).copyWith(
        value: value,
        capturedAt: DateTime.now(),
      );
    });
    final updatedMember = member.copyWith(fields: updatedFields);
    final members = Map<PartyRole, PartyMemberState>.from(state.party.members);
    members[role] = updatedMember;
    for (final entry in values.entries) {
      _propagateMirrorValue(members, role, entry.key, entry.value);
    }
    _emit(
      state.copyWith(
        party: state.party.copyWith(members: members),
      ),
    );
  }

  void setMirrorFromRequested(PartyRole role, bool enabled) {
    if (role == PartyRole.requestedBy) return;
    if (enabled) {
      _enableMirrorLink(role);
    } else {
      _disableMirrorLink(role);
    }
  }

  void _enableMirrorLink(PartyRole role) {
    const requested = PartyRole.requestedBy;
    if (_mirrorGraph[role]?.contains(requested) ?? false) {
      return;
    }

    final members = Map<PartyRole, PartyMemberState>.from(state.party.members);
    final roleMember = members[role];
    final requestedMember = members[requested];
    if (roleMember == null || requestedMember == null) {
      return;
    }

    if (!roleMember.mirrorsRequested) {
      members[role] = roleMember.copyWith(mirrorsRequested: true);
    }

    _linkRoles(requested, role);
    final synchronized = _synchronizeLink(members, requested, role);
    _emit(
      state.copyWith(
        party: state.party.copyWith(members: synchronized),
      ),
    );
  }

  void _disableMirrorLink(PartyRole role) {
    const requested = PartyRole.requestedBy;
    final isLinked = _mirrorGraph[role]?.contains(requested) ?? false;
    if (!isLinked) {
      final member = state.party.members[role];
      if (member == null || !member.mirrorsRequested) return;
      final members =
          Map<PartyRole, PartyMemberState>.from(state.party.members);
      members[role] = member.copyWith(mirrorsRequested: false);
      _emit(
        state.copyWith(
          party: state.party.copyWith(members: members),
        ),
      );
      return;
    }

    _unlinkRoles(requested, role);
    final member = state.party.members[role];
    if (member == null) return;
    final members = Map<PartyRole, PartyMemberState>.from(state.party.members);
    members[role] = member.copyWith(mirrorsRequested: false);
    _emit(
      state.copyWith(
        party: state.party.copyWith(members: members),
      ),
    );
  }

  Map<PartyRole, PartyMemberState> _synchronizeLink(
    Map<PartyRole, PartyMemberState> members,
    PartyRole a,
    PartyRole b,
  ) {
    final updated = Map<PartyRole, PartyMemberState>.from(members);
    final aMember = updated[a];
    final bMember = updated[b];
    if (aMember == null || bMember == null) {
      return updated;
    }

    final aFields = Map<PartyField, PartyFieldState>.from(aMember.fields);
    final baseB = updated[b]!;
    final bFields = Map<PartyField, PartyFieldState>.from(baseB.fields);

    bool aChanged = false;
    bool bChanged = false;

    for (final field in PartyField.values) {
      final aValue = aFields[field]?.value ?? '';
      final bValue = bFields[field]?.value ?? '';
      final trimmedA = aValue.trim();
      final trimmedB = bValue.trim();
      String resolved;
      if (trimmedA.isNotEmpty) {
        resolved = aValue;
      } else if (trimmedB.isNotEmpty) {
        resolved = bValue;
      } else {
        resolved = '';
      }

      if (aValue != resolved) {
        aFields[field] = (aFields[field] ?? const PartyFieldState())
            .copyWith(value: resolved);
        aChanged = true;
      }
      if (bValue != resolved) {
        bFields[field] = (bFields[field] ?? const PartyFieldState())
            .copyWith(value: resolved);
        bChanged = true;
      }
    }

    updated[a] = aChanged ? aMember.copyWith(fields: aFields) : aMember;
    updated[b] = bChanged ? baseB.copyWith(fields: bFields) : baseB;
    return updated;
  }

  void _propagateMirrorValue(
    Map<PartyRole, PartyMemberState> members,
    PartyRole source,
    PartyField field,
    String value, {
    PartyRole? origin,
  }) {
    final targets = _mirrorGraph[source];
    if (targets == null) return;
    for (final target in targets) {
      if (target == origin) continue;
      final targetMember = members[target];
      if (targetMember == null) continue;
      final currentValue = targetMember.fields[field]?.value ?? '';
      if (currentValue != value) {
        final updatedFields =
            Map<PartyField, PartyFieldState>.from(targetMember.fields);
        updatedFields[field] = (updatedFields[field] ?? const PartyFieldState())
            .copyWith(value: value);
        members[target] = targetMember.copyWith(fields: updatedFields);
        _propagateMirrorValue(members, target, field, value, origin: source);
      }
    }
  }

  void _linkRoles(PartyRole a, PartyRole b) {
    _mirrorGraph.putIfAbsent(a, () => <PartyRole>{}).add(b);
    _mirrorGraph.putIfAbsent(b, () => <PartyRole>{}).add(a);
  }

  void _unlinkRoles(PartyRole a, PartyRole b) {
    final setA = _mirrorGraph[a];
    setA?.remove(b);
    if (setA != null && setA.isEmpty) {
      _mirrorGraph.remove(a);
    }
    final setB = _mirrorGraph[b];
    setB?.remove(a);
    if (setB != null && setB.isEmpty) {
      _mirrorGraph.remove(b);
    }
  }

  void _emit(AppSessionState newState) {
    final normalized = _normalizeEquipmentState(newState);
    if (state == normalized) return;
    state = normalized;
    _isDirty = state != _initialState;
  }

  String addPrimaryDevice(PrimaryDeviceType type) {
    final id = _generateId();
    final prefix = prefixFor(type);
    final accessories = <AccessoryState>[];
    if (type == PrimaryDeviceType.laptop) {
      accessories.add(
        AccessoryState(
          id: _generateId(),
          label: 'With Adapter',
          selected: true,
          suggested: true,
        ),
      );
    } else if (type == PrimaryDeviceType.phone) {
      accessories.add(
        AccessoryState(
          id: _generateId(),
          label: 'With Charger',
          selected: true,
          suggested: true,
        ),
      );
    }
    final newDevice = PrimaryDeviceState(
      id: id,
      type: type,
      makeModel: '',
      assetTag:
          type == PrimaryDeviceType.laptop || type == PrimaryDeviceType.phone
              ? prefix
              : null,
      accessories: accessories,
    );
    _emit(
      state.copyWith(
        equipment: state.equipment.copyWith(
          primaries: [...state.equipment.primaries, newDevice],
        ),
      ),
    );
    return id;
  }

  void removePrimaryDevice(String id) {
    _emit(
      state.copyWith(
        equipment: state.equipment.copyWith(
          primaries: state.equipment.primaries
              .where((device) => device.id != id)
              .toList(),
        ),
      ),
    );
  }

  void updatePrimaryDevice(
      String id, PrimaryDeviceState Function(PrimaryDeviceState) updater) {
    final updated = state.equipment.primaries.map((device) {
      if (device.id == id) {
        final result = updater(device);
        return _normalizeDevice(result);
      }
      return device;
    }).toList();
    _emit(
      state.copyWith(
        equipment: state.equipment.copyWith(primaries: updated),
      ),
    );
  }

  void toggleAccessory(
      {required String primaryId,
      required String accessoryId,
      required bool selected}) {
    updatePrimaryDevice(primaryId, (device) {
      final updatedAccessories = device.accessories.map((accessory) {
        if (accessory.id == accessoryId) {
          return accessory.copyWith(selected: selected);
        }
        return accessory;
      }).toList();
      return device.copyWith(accessories: updatedAccessories);
    });
  }

  void addCustomAccessory({required String primaryId, required String label}) {
    updatePrimaryDevice(primaryId, (device) {
      final accessory = AccessoryState(
          id: _generateId(), label: label, selected: true, suggested: false);
      return device.copyWith(accessories: [...device.accessories, accessory]);
    });
  }

  void setReplacementPhase({required String primaryId, required bool isOld}) {
    updatePrimaryDevice(
        primaryId, (device) => device.copyWith(isReplacementOld: isOld));
  }

  void removeAccessory(
      {required String primaryId, required String accessoryId}) {
    updatePrimaryDevice(primaryId, (device) {
      final list =
          device.accessories.where((acc) => acc.id != accessoryId).toList();
      return device.copyWith(accessories: list);
    });
  }

  void reorderAccessories(
      {required String primaryId,
      required int oldIndex,
      required int newIndex}) {
    updatePrimaryDevice(primaryId, (device) {
      final list = [...device.accessories];
      if (newIndex > oldIndex) newIndex -= 1;
      final removed = list.removeAt(oldIndex);
      list.insert(newIndex, removed);
      return device.copyWith(accessories: list);
    });
  }

  void setLocation(LocationCode location) {
    final updatedWorkflow = state.workflow.copyWith(location: location);
    final primaries = state.equipment.primaries.map((device) {
      if (device.type == PrimaryDeviceType.laptop ||
          device.type == PrimaryDeviceType.phone) {
        final currentAsset = device.assetTag ?? '';
        final prefix = prefixFor(device.type, locationOverride: location);
        if (!currentAsset.startsWith(prefix)) {
          final suffix = normalizeAssetTagSuffix(currentAsset.replaceFirst(
              RegExp('^${RegExp.escape(prefixFor(device.type))}'), ''));
          return device.copyWith(assetTag: prefix + suffix);
        }
      }
      return device;
    }).toList();
    _emit(
      state.copyWith(
        workflow: updatedWorkflow,
        equipment: state.equipment.copyWith(primaries: primaries),
      ),
    );
  }

  void setDateReceived(DateTime? value) {
    _emit(
      state.copyWith(
        workflow: state.workflow.copyWith(dateReceived: value),
      ),
    );
  }

  void setDateReturned(DateTime? value) {
    _emit(
      state.copyWith(
        workflow: state.workflow.copyWith(dateReturned: value),
      ),
    );
  }

  void setDataHandling(bool confirmed) {
    _emit(
      state.copyWith(
        workflow: state.workflow.copyWith(dataHandlingConfirmed: confirmed),
      ),
    );
  }

  String prefixFor(PrimaryDeviceType type, {LocationCode? locationOverride}) {
    final location = locationOverride ??
        state.workflow.location ??
        _currentUser.defaultLocation;
    return buildAssetTagPrefix(location, type);
  }

  PrimaryDeviceState? deviceById(String id) {
    for (final device in state.equipment.primaries) {
      if (device.id == id) {
        return device;
      }
    }
    return null;
  }

  String _normalizeAssetTag(PrimaryDeviceType type, String? raw,
      {WorkflowSessionState? workflow}) {
    if (raw == null || raw.isEmpty) {
      return prefixFor(type, locationOverride: workflow?.location);
    }
    final prefix = prefixFor(type, locationOverride: workflow?.location);
    var normalized = raw.toUpperCase().replaceAll(' ', '');
    if (!normalized.startsWith(prefix)) {
      normalized = prefix + normalizeAssetTagSuffix(normalized);
    }
    return normalized;
  }

  PrimaryDeviceState _normalizeDevice(PrimaryDeviceState device,
      {WorkflowSessionState? workflow}) {
    var normalized = device.copyWith(
      assetTag: _normalizeAssetTag(
        device.type,
        device.assetTag,
        workflow: workflow ?? state.workflow,
      ),
    );
    if (device.type == PrimaryDeviceType.laptop) {
      normalized = normalized.copyWith(
        makeModel: _normalizeLaptopModel(normalized.makeModel),
      );
    }
    return normalized;
  }

  AppSessionState _normalizeEquipmentState(AppSessionState value) {
    final primaries = value.equipment.primaries
        .map((device) => _normalizeDevice(device, workflow: value.workflow))
        .toList();
    return value.copyWith(
      equipment: value.equipment.copyWith(primaries: primaries),
    );
  }

  String _normalizeLaptopModel(String value) {
    final normalized = normalizeDellLatitudeModel(value);
    if (normalized == null) return value.trim().toUpperCase();
    return normalized.trim().toUpperCase();
  }

  static String _generateId() =>
      Random().nextInt(1 << 32).toRadixString(16) +
      DateTime.now().microsecondsSinceEpoch.toString();

  AppSessionState get initialState => _initialState;
}

final sessionControllerProvider =
    StateNotifierProvider.family<SessionController, AppSessionState, FormType>(
        (ref, formType) {
  final currentUser = ref.watch(currentUserProfileProvider);
  return SessionController(formType: formType, currentUser: currentUser);
});
