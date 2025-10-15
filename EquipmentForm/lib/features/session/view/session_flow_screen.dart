import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../data/models/session.dart';
import 'session_scope.dart';
import '../controllers/session_controller.dart';
import '../domain/session_models.dart';
import '../../shared/domain/normalizers.dart';
import 'widgets/equipment_session_step.dart';
import 'widgets/party_session_step.dart';
import 'widgets/review_session_step.dart';
import 'widgets/workflow_session_step.dart';

class SessionFlowScreen extends ConsumerStatefulWidget {
  const SessionFlowScreen({super.key, required this.formType});

  final FormType formType;

  @override
  ConsumerState<SessionFlowScreen> createState() => _SessionFlowScreenState();
}

class _SessionFlowScreenState extends ConsumerState<SessionFlowScreen> {
  late final PageController _pageController;
  int _currentStep = 0;

  static const _stepTitles = [
    'Parties',
    'Equipment',
    'Workflow',
    'Review',
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    // touch controller to ensure initialization.
    ref.read(sessionControllerProvider(widget.formType));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionControllerProvider(widget.formType));
    final canProceed = _canProceedFromStep(_currentStep, state);

    return SessionScope(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackNavigation,
          ),
          title: Text('${widget.formType.name.toUpperCase()} Session'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'change_form') {
                  _handleChangeFormType();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'change_form',
                  child: Text('Change Form Type'),
                ),
              ],
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _SessionStepHeader(
                currentStep: _currentStep,
                stepTitles: _stepTitles,
                onStepTapped: _handleStepTap,
              ),
              const Divider(height: 1),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    PartySessionStep(formType: widget.formType),
                    EquipmentSessionStep(formType: widget.formType),
                    WorkflowSessionStep(formType: widget.formType),
                    ReviewSessionStep(formType: widget.formType),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: SingleChildScrollView(
            key: const ValueKey('sessionFlowActionsScroll'),
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 460;
                final primaryButton = SizedBox(
                  width: compact ? double.infinity : null,
                  child: ElevatedButton.icon(
                    onPressed:
                        canProceed ? () => _goToStep(_currentStep + 1) : null,
                    icon: Icon(_currentStep >= _stepTitles.length - 1
                        ? Icons.picture_as_pdf
                        : Icons.arrow_forward),
                    label: Text(_currentStep >= _stepTitles.length - 1
                        ? 'Export'
                        : 'Continue'),
                  ),
                );

                if (compact) {
                  return Row(
                    children: [
                      if (_currentStep > 0)
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz),
                          onSelected: (value) {
                            if (value == 'back') {
                              _goToStep(_currentStep - 1);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'back', child: Text('Back')),
                          ],
                        )
                      else
                        const SizedBox(width: 48),
                      const SizedBox(width: 12),
                      Expanded(child: primaryButton),
                    ],
                  );
                }

                return Row(
                  children: [
                    if (_currentStep > 0)
                      OutlinedButton.icon(
                        onPressed: () => _goToStep(_currentStep - 1),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                      )
                    else
                      const SizedBox(width: 96),
                    const Spacer(),
                    primaryButton,
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleChangeFormType() async {
    final confirmed = await _confirmLeaveSession();
    if (!confirmed || !mounted) return;
    context.goNamed(AppRoute.formTypeSelect.name);
  }

  void _goToStep(int index) {
    if (index < 0) return;
    if (index >= _stepTitles.length) {
      // Trigger export from review step widget via notifier.
      ref.read(reviewStepActionProvider(widget.formType)).export();
      return;
    }
    setState(() => _currentStep = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleBackNavigation() async {
    final shouldLeave = await _confirmLeaveSession();
    if (shouldLeave && mounted) {
      context.goNamed(AppRoute.formTypeSelect.name);
    }
  }

  Future<bool> _confirmLeaveSession() async {
    final controller =
        ref.read(sessionControllerProvider(widget.formType).notifier);
    if (!controller.isDirty) {
      return true;
    }
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave session?'),
            content: const Text('Unsaved changes will be lost. Continue?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Stay'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _handleStepTap(int index) async {
    if (index == _currentStep) return;
    final proceed = await _confirmNavigation(targetStep: index);
    if (proceed && mounted) {
      _goToStep(index);
    }
  }

  Future<bool> _confirmNavigation({required int targetStep}) async {
    final targetLabel = _stepTitles[targetStep];
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave current step?'),
            content: Text(
                'Move to "$targetLabel"? Recent entries are saved automatically.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Stay'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Continue'),
              ),
            ],
          ),
        ) ??
        false;
  }

  bool _canProceedFromStep(int step, AppSessionState state) {
    switch (step) {
      case 0:
        return _validateParty(state);
      case 1:
        return _validateEquipment(state);
      case 2:
        return _validateWorkflow(state);
      case 3:
        return true;
      default:
        return true;
    }
  }

  bool _validateParty(AppSessionState state) {
    for (final member in state.party.members.values) {
      for (final field in PartyField.values) {
        final value = member.fields[field]?.value.trim() ?? '';
        if (value.isEmpty) {
          return false;
        }
      }
    }
    return state.party.members.isNotEmpty;
  }

  bool _validateEquipment(AppSessionState state) {
    if (state.equipment.primaries.isEmpty) {
      return false;
    }
    for (final device in state.equipment.primaries) {
      if (device.makeModel.trim().isEmpty) {
        return false;
      }
      if (device.type == PrimaryDeviceType.laptop) {
        final assetError = validateAssetTag(device.assetTag);
        if (assetError != null) return false;
        if ((device.serviceTag ?? '').trim().isEmpty) return false;
      }
      if (device.type == PrimaryDeviceType.phone) {
        final imeiError = validateImei(device.imei);
        if (imeiError != null) return false;
        final asset = device.assetTag;
        if (asset != null &&
            asset.trim().isNotEmpty &&
            validateAssetTag(asset) != null) {
          return false;
        }
      }
    }
    return true;
  }

  bool _validateWorkflow(AppSessionState state) {
    final workflow = state.workflow;
    switch (workflow.formType) {
      case FormType.received:
        return workflow.dateReceived != null;
      case FormType.returned:
        return workflow.dateReturned != null && workflow.dataHandlingConfirmed;
      case FormType.replaced:
        return workflow.dateReceived != null &&
            workflow.dateReturned != null &&
            workflow.dataHandlingConfirmed;
    }
  }
}

class _SessionStepHeader extends StatelessWidget {
  const _SessionStepHeader({
    required this.currentStep,
    required this.stepTitles,
    required this.onStepTapped,
  });

  final int currentStep;
  final List<String> stepTitles;
  final ValueChanged<int> onStepTapped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < stepTitles.length; i++) ...[
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => onStepTapped(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: i <= currentStep
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Text('${i + 1}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: i <= currentStep
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurfaceVariant)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stepTitles[i],
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: i == currentStep
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (i < stepTitles.length - 1)
              SizedBox(
                width: 24,
                child: Divider(
                  color: i < currentStep
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outlineVariant,
                  thickness: 2,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
