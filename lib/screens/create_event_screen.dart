import 'package:flutter/material.dart';

import 'create_event/create_event_screen.dart' as create_event;

/// Conteneur d'onglet pour la création d'événement dans [MainScaffold].
class CreateEventTabContent extends StatelessWidget {
  final String accountType;
  final VoidCallback? onBack;

  const CreateEventTabContent({
    super.key,
    this.accountType = 'gratuit',
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return create_event.CreateEventScreen(
      accountType: accountType,
      onBack: onBack,
    );
  }
}

/// Alias conservé pour compatibilité.
class CreateEventScreen extends CreateEventTabContent {
  const CreateEventScreen({super.key, super.accountType, super.onBack});
}
