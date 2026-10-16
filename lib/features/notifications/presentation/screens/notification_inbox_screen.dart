import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/modern_app_header.dart';
import '../../data/models/notification_model.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';
import 'notification_preferences_screen.dart';

class NotificationInboxScreen extends StatelessWidget {
  const NotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationBloc>.value(
      value: ServiceLocator.notificationBloc,
      child: const _NotificationInboxView(),
    );
  }
}

class _NotificationInboxView extends StatefulWidget {
  const _NotificationInboxView();

  @override
  State<_NotificationInboxView> createState() => _NotificationInboxViewState();
}

class _NotificationInboxViewState extends State<_NotificationInboxView> {
  String _selectedFilter = 'Toutes';

  @override
  void initState() {
    super.initState();
    ServiceLocator.notificationBloc.add(const LoadNotificationsEvent());
  }

  List<NotificationItemModel> _filterList(List<NotificationItemModel> all) {
    if (_selectedFilter == 'Non lues') {
      return all.where((n) => !n.isRead).toList();
    } else if (_selectedFilter == 'Fertilité') {
      return all.where((n) => n.type.toLowerCase() == 'fenetre_fertile').toList();
    } else if (_selectedFilter == 'Rappels') {
      return all.where((n) => n.type.toLowerCase() == 'rappel_saisie').toList();
    }
    return all;
  }

  void _showNotificationDetail(NotificationItemModel notif) {
    if (!notif.isRead) {
      context.read<NotificationBloc>().add(MarkNotificationAsReadEvent(notif.id));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: notif.accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(notif.iconData, color: notif.accentColor, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif.categoryLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: notif.accentColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          notif.timeAgoFormatted,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                notif.titre,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                notif.message,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Compris',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: ModernAppHeader(
        title: 'Centre d’alertes',
        subtitle: 'Rappels & fertilité',
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppTheme.textDark, size: 22),
            tooltip: 'Préférences',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationPreferencesScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.done_all_rounded, color: AppTheme.primary, size: 22),
            tooltip: 'Tout marquer comme lu',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.read<NotificationBloc>().add(MarkAllNotificationsAsReadEvent());
            },
          ),
        ],
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
                        ServiceLocator.notificationBloc.add(const LoadNotificationsEvent());
                      },
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is NotificationLoadedState) {
            final filtered = _filterList(state.notifications);

            return RefreshIndicator(
              color: AppTheme.primary,
              onRefresh: () async {
                context.read<NotificationBloc>().add(const LoadNotificationsEvent());
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  // Filtres en chips
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('Toutes', state.notifications.length),
                            const SizedBox(width: 8),
                            _buildFilterChip('Non lues', state.unreadCount),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'Fertilité',
                              state.notifications
                                  .where((n) => n.type.toLowerCase() == 'fenetre_fertile')
                                  .length,
                            ),
                            const SizedBox(width: 8),
                            _buildFilterChip(
                              'Rappels',
                              state.notifications
                                  .where((n) => n.type.toLowerCase() == 'rappel_saisie')
                                  .length,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Liste des alertes
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_none_rounded,
                                  size: 40,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Aucune notification',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Vous êtes à jour ! Vos rappels et alertes physiologiques apparaîtront ici.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppTheme.textMuted,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 24),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.primary,
                                  side: const BorderSide(color: AppTheme.primary),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () {
                                  context
                                      .read<NotificationBloc>()
                                      .add(TriggerTestNotificationEvent());
                                },
                                icon: const Icon(Icons.bolt_rounded, size: 18),
                                label: const Text('Simuler une alerte test'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final notif = filtered[index];
                            return _buildNotificationCard(notif);
                          },
                          childCount: filtered.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 40)),
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

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.borderLight,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textDark,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : AppTheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItemModel notif) {
    final isUnread = !notif.isRead;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnread
            ? notif.accentColor.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnread
              ? notif.accentColor.withValues(alpha: 0.35)
              : AppTheme.borderLight.withValues(alpha: 0.8),
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            _showNotificationDetail(notif);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: notif.accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(notif.iconData, color: notif.accentColor, size: 22),
                ),
                const SizedBox(width: 14),

                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: notif.accentColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              notif.categoryLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: notif.accentColor,
                              ),
                            ),
                          ),
                          Text(
                            notif.timeAgoFormatted,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notif.titre,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Pastille non lue
                if (isUnread) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: notif.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
