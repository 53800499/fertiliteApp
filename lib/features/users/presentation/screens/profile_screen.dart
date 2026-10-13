import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/error/error_feedback.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../privacy/presentation/screens/privacy_settings_screen.dart';
import '../../data/models/user_profile_model.dart';
import 'profile_setup_screen.dart';
import '../../../../core/network/network_cubit.dart';
import '../../../../core/widgets/offline_state_view.dart';
import '../../../../core/widgets/modern_app_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  FullUserProfileModel? _profile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ServiceLocator.userRepository.getProfile();
      if (mounted) {
        setState(() {
          _profile = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = ApiException.getDisplayMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  bool _isOffline(BuildContext context) {
    try {
      return !BlocProvider.of<NetworkCubit>(context).state.isOnline;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: ModernAppHeader(
        subtitle: 'Compte & Paramètres',
        title: 'Mon Profil',
        onRefresh: _loadProfile,
        actions: [
          const SizedBox(width: 8),
          ModernHeaderIconButton(
            icon: Icons.logout_rounded,
            tooltip: 'Déconnexion',
            iconColor: AppTheme.textMuted,
            onPressed: () {
              context.read<AuthBloc>().add(LogoutRequestedEvent());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _errorMessage != null
              ? Builder(
                  builder: (context) {
                    final isOffline = _isOffline(context) ||
                        _errorMessage!.toLowerCase().contains('connexion') ||
                        _errorMessage!.toLowerCase().contains('hors ligne') ||
                        _errorMessage!.toLowerCase().contains('socketexception') ||
                        _errorMessage!.toLowerCase().contains('failed host lookup');
                    if (isOffline) {
                      return OfflineStateView(onRetry: _loadProfile);
                    }
                    return AppErrorEmptyView(
                      error: _errorMessage,
                      onRetry: _loadProfile,
                    );
                  },
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Bannière Hero Utilisatrice
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: AppTheme.softHeroGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: AppTheme.floatingShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.22),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                              ),
                              child: Center(
                                child: Text(
                                  (_profile?.profil.prenom?.isNotEmpty ?? false)
                                      ? _profile!.profil.prenom![0].toUpperCase()
                                      : 'F',
                                  style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _profile?.profil.prenom ?? 'Utilisatrice',
                                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _profile?.email ?? '',
                                    style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.85)),
                                  ),
                                  if (_profile?.dateNaissance != null) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Née le ${_profile!.dateNaissance}',
                                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Builder(
                                    builder: (context) {
                                      final isOnline = !_isOffline(context);
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: isOnline
                                              ? Colors.white.withValues(alpha: 0.22)
                                              : const Color(0xFFFFF3E0),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isOnline ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                                              size: 12,
                                              color: isOnline ? Colors.white : const Color(0xFFE65100),
                                            ),
                                            const SizedBox(width: 5),
                                            Text(
                                              isOnline ? 'En ligne (synchronisé)' : 'Mode local hors-ligne',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: isOnline ? Colors.white : const Color(0xFFBF360C),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Grille de repères physiologiques (2x2)
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Durée du cycle',
                              value: '${_profile?.profil.dureeMoyenneCycle ?? 28} j',
                              subtitle: 'Moyenne habituelle',
                              icon: Icons.calendar_today_rounded,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Durée des règles',
                              value: '${_profile?.profil.dureeMoyenneRegles ?? 5} j',
                              subtitle: 'Flux menstruel',
                              icon: Icons.water_drop_rounded,
                              color: AppTheme.periodColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Objectif',
                              value: _formatObjective(_profile?.profil.objectifPrincipal),
                              subtitle: 'Orientation de calcul',
                              icon: Icons.flag_rounded,
                              color: AppTheme.accentRose,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricTile(
                              title: 'Régularité',
                              value: (_profile?.profil.irregulariteDeclaree ?? false) ? 'Irrégulier' : 'Régulier',
                              subtitle: 'Marge algorithmique',
                              icon: Icons.auto_graph_rounded,
                              color: (_profile?.profil.irregulariteDeclaree ?? false) ? Colors.amber.shade700 : Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Menu d'actions rapides modernes
                      const Text(
                        'Paramètres & Gestion',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 12),

                      _buildActionCard(
                        icon: Icons.tune_rounded,
                        title: 'Ajuster les paramètres du cycle',
                        subtitle: 'Modifier l\'objectif, durées habituelles et régularité',
                        color: AppTheme.primary,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ProfileSetupScreen(onCompleted: () => Navigator.pop(context))),
                          );
                          _loadProfile();
                        },
                      ),
                      const SizedBox(height: 10),

                      _buildActionCard(
                        icon: Icons.verified_user_rounded,
                        title: 'Confidentialité, RGPD & Sessions',
                        subtitle: 'Protection des données de santé, historique et sécurité',
                        color: Colors.teal.shade700,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
                          );
                          _loadProfile();
                        },
                      ),
                      const SizedBox(height: 10),

                      _buildActionCard(
                        icon: Icons.logout_rounded,
                        title: 'Se déconnecter',
                        subtitle: 'Fermer la session sur cet appareil',
                        color: Colors.red.shade600,
                        onTap: () {
                          context.read<AuthBloc>().add(LogoutRequestedEvent());
                        },
                      ),
                      const SizedBox(height: 90),
                    ],
                  ),
                ),
    );
  }

  String _formatObjective(String? obj) {
    switch (obj) {
      case 'concevoir':
        return 'Conception';
      case 'suivre_cycle':
        return 'Suivi du cycle';
      case 'contraception_naturelle':
        return 'Observation';
      default:
        return 'Suivi';
    }
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppTheme.textMuted)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppTheme.textLight)),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderLight),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}
