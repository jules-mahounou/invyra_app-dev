import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'create_event_utils.dart';
import 'steps/step1_basic_info.dart';
import 'steps/step2_template.dart';
import 'steps/step3_guests.dart';

/// Écran principal de création d'événement — gère le stepper et l'état partagé.
class CreateEventScreen extends StatefulWidget {
  final String accountType;
  final VoidCallback? onBack;

  const CreateEventScreen({
    super.key,
    this.accountType = 'gratuit',
    this.onBack,
  });

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  String? _eventId;
  String? _eventType;

  int _currentStep = 1;

  void _onStep1Completed(String eventId, String eventType) {
    setState(() {
      _eventId = eventId;
      _eventType = eventType;
      _currentStep = 2;
    });
  }

  void _onStep2Completed(String _) {
    setState(() => _currentStep = 3);
  }

  void _finishCreation({required bool showSuccessMessage}) {
    if (showSuccessMessage) {
      showCreateEventSuccessSnackBar(context, 'Événement créé avec succès !');
    }
    widget.onBack?.call();
  }

  @override
  Widget build(BuildContext context) {
    Widget stepContent;
    switch (_currentStep) {
      case 1:
        stepContent = Step1BasicInfo(onStepCompleted: _onStep1Completed);
      case 2:
        stepContent = Step2Template(
          eventId: _eventId!,
          eventType: _eventType!,
          accountType: widget.accountType,
          onStepCompleted: _onStep2Completed,
          onBack: () => setState(() => _currentStep = 1),
        );
      case 3:
        stepContent = Step3Guests(
          eventId: _eventId!,
          onCreateAndSend: () => _finishCreation(showSuccessMessage: true),
          onFinishWithoutSending: () => _finishCreation(showSuccessMessage: false),
          onBackToEvents: () => _finishCreation(showSuccessMessage: false),
        );
      default:
        stepContent = const SizedBox.shrink();
    }

    return Material(
      color: AppColors.blancCasse,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppConstants.maxContentWidth),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CreateEventHero(
                  currentStep: _currentStep,
                  onBack: _currentStep == 1 ? widget.onBack : null,
                ),
                const SizedBox(height: AppSpacing.xl),
                CreateEventStepIndicator(currentStep: _currentStep),
                const SizedBox(height: AppSpacing.xl),
                stepContent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
