import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/modern_app_header.dart';
import '../../data/models/notification_preferences_model.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';

class NotificationPreferencesScreen extends StatelessWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationBloc>.value(
      value: ServiceLocator.notificationBloc,
      child: const _NotificationPreferencesView(),
    );
  }
}

class _NotificationPreferencesView extends StatefulWidget {
  const _NotificationPreferencesView();

  @override
  State<_NotificationPreferencesView> createState() =>
      _NotificationPreferencesViewState();
}

class _NotificationPreferencesViewState
    extends State<_NotificationPreferencesView> {
  @override
  void initState() {
    super.initState();
    ServiceLocator.notificationBloc.add(LoadPreferencesEvent());
  }

  void _updatePref(
    NotificationPreferencesModel current,
    NotificationPreferencesModel updated,
  ) {
    HapticFeedback.selectionClick();
    context.read<NotificationBloc>().add(UpdatePreferencesEvent(updated));
  }

  Future<void> _pickReminderTime(
    BuildContext context,
    NotificationPreferencesModel prefs,
  ) async {
    final parts = prefs.heureRappelSaisie.split(':');
    final initialHour = int.tryParse(parts.first) ?? 20;
    final initialMinute =
        parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;

    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      helpText: 'HEURE DU RAPPEL QUOTIDIEN',
      confirmText: 'VALIDER',
      cancelText: 'ANNULER',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selected != null) {
      final hourStr = selected.hour.toString().padLeft(2, '0');
      final minStr = selected.minute.toString().padLeft(2, '0');
      final newTime = '$hourStr:$minStr';

      _updatePref(prefs, prefs.copyWith(heureRappelSaisie: newTime));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const ModernAppHeader(
        title: 'Rappels & Alertes',
        subtitle: 'Préférences et notifications',
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationLoadedState && state.feedbackMessage != null) {
            AppFeedback.showSuccess(context, message: state.feedbackMessage!);
          }
        },
        builder: (context, state) {
          if (state is NotificationLoadingState || state is NotificationInitialState) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          if (state is NotificationErrorState) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                    const SizedBox(height: 12),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        ServiceLocator.notificationBloc.add(LoadPreferencesEvent());
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is NotificationLoadedState) {
            final prefs = state.preferences;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bannière Explicative
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: AppTheme.softHeroGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppTheme.floatingShadow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Alertes discrètes & bienveillantes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'FertiliteApp vous alerte au moment opportun sans saturer votre quotidien.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 1: UC-20 Rappel Quotidien de Saisie
                  _buildSectionHeader(
                    title: 'Rappels de saisie quotidienne',
                    icon: Icons.edit_calendar_rounded,
                    tag: 'UC-20',
                  ),
                  const SizedBox(height: 12),
                  _buildCard([
                    _buildSwitchTile(
                      title: 'Moment d’écoute du corps',
                      subtitle:
                          'Rappel discret en fin de journée uniquement si aucune observation n’a été enregistrée',
                      value: prefs.rappelSaisieActif,
                      onChanged: (val) {
                        _updatePref(prefs, prefs.copyWith(rappelSaisieActif: val));
                      },
                    ),
                    if (prefs.rappelSaisieActif) ...[
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        title: const Text(
                          'Heure habituelle du rappel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        subtitle: const Text(
                          'Heure suggérée pour noter vos ressentis',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: AppTheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                prefs.heureRappelSaisie,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        onTap: () => _pickReminderTime(context, prefs),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 24),

                  // Section 2: UC-21 Alertes Physiologiques du Cycle
                  _buildSectionHeader(
                    title: 'Alertes du cycle & fertilité',
                    icon: Icons.auto_awesome_rounded,
                    tag: 'UC-21',
                  ),
                  const SizedBox(height: 12),
                  _buildCard([
                    _buildSwitchTile(
                      title: 'Entrée en fenêtre fertile (J-2)',
                      subtitle:
                          'Alerte préventive 48h avant le début de votre fenêtre de haute fertilité',
                      badge: 'Recommandé',
                      badgeColor: AppTheme.fertileHighColor,
                      value: prefs.alerteFenetreFertile,
                      onChanged: (val) {
                        _updatePref(
                            prefs, prefs.copyWith(alerteFenetreFertile: val));
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildSwitchTile(
                      title: 'Prévision des prochaines règles',
                      subtitle:
                          'Alerte 24 à 48h avant le début estimé de vos menstruations',
                      badgeColor: AppTheme.periodColor,
                      value: prefs.alerteReglesPrevues,
                      onChanged: (val) {
                        _updatePref(
                            prefs, prefs.copyWith(alerteReglesPrevues: val));
                      },
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // Section 3: UC-22 Canaux de Diffusion
                  _buildSectionHeader(
                    title: 'Canaux de notification',
                    icon: Icons.cell_tower_rounded,
                    tag: 'UC-22',
                  ),
                  const SizedBox(height: 12),
                  _buildCard([
                    _buildSwitchTile(
                      title: 'Notifications Push mobiles',
                      subtitle: 'Alertes sur l’écran de verrouillage de cet appareil',
                      value: prefs.canalPush,
                      onChanged: (val) {
                        _updatePref(prefs, prefs.copyWith(canalPush: val));
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildSwitchTile(
                      title: 'Boîte de réception In-App',
                      subtitle: 'Historique des alertes dans le centre de notifications',
                      value: prefs.canalInApp,
                      onChanged: (val) {
                        _updatePref(prefs, prefs.copyWith(canalInApp: val));
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _buildSwitchTile(
                      title: 'Récapitulatif par e-mail',
                      subtitle: 'Synthèse hebdomadaire de santé et prédictions',
                      value: prefs.canalEmail,
                      onChanged: (val) {
                        _updatePref(prefs, prefs.copyWith(canalEmail: val));
                      },
                    ),
                  ]),
                  const SizedBox(height: 28),

                  // Section 4: Diagnostic & Simulation
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                color: Colors.teal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tester le canal d’alerte',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                  Text(
                                    'Simule l’émission d’un rappel immédiat',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            context
                                .read<NotificationBloc>()
                                .add(TriggerTestNotificationEvent());
                          },
                          icon: const Icon(Icons.bolt_rounded, size: 20),
                          label: const Text(
                            'Envoyer une alerte de test',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            );
          }

          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required String tag,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tag,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? badge,
    Color? badgeColor,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      activeTrackColor: AppTheme.primary,
      activeThumbColor: Colors.white,
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: (badgeColor ?? AppTheme.primary).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: badgeColor ?? AppTheme.primary,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            height: 1.3,
            color: AppTheme.textMuted,
          ),
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }
}
