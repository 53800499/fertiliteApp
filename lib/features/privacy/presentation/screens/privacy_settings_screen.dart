import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../users/data/models/user_profile_model.dart';
import '../../data/models/privacy_models.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  UserPrivacySettingsModel? _settings;
  List<ConsentementModel> _consents = [];
  List<ActiveSessionModel> _sessions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final s = await ServiceLocator.privacyRepository.getSettings();
      final c = await ServiceLocator.privacyRepository.getConsents();
      final sess = await ServiceLocator.privacyRepository.getActiveSessions();

      if (mounted) {
        setState(() {
          _settings = s;
          _consents = c;
          _sessions = sess;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateSetting(UserPrivacySettingsModel newSettings) async {
    try {
      final updated = await ServiceLocator.privacyRepository.updateSettings(newSettings);
      setState(() => _settings = updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètre de confidentialité mis à jour'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _revokeSession(String sessionId) async {
    try {
      await ServiceLocator.privacyRepository.revokeSession(sessionId);
      await _loadAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appareil déconnecté avec succès'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 26),
            SizedBox(width: 10),
            Text('Supprimer mon compte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cette action est définitive. Conformément au RGPD, toutes vos données de cycle et de santé seront purgées sous 30 jours.',
                style: TextStyle(fontSize: 12.5, color: AppTheme.textMuted, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Votre mot de passe actuel*',
                  prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motif de votre départ (optionnel)',
                  hintText: 'Ex: Projet de conception abouti',
                  prefixIcon: Icon(Icons.chat_bubble_outline_rounded, size: 20),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final pwd = passwordController.text;
              if (pwd.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mot de passe requis pour confirmer'), behavior: SnackBarBehavior.floating),
                );
                return;
              }
              Navigator.pop(ctx);
              try {
                await ServiceLocator.userRepository.requestAccountDeletion(
                  password: pwd,
                  reason: reasonController.text.trim().isNotEmpty ? reasonController.text.trim() : null,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demande enregistrée. Déconnexion...'), behavior: SnackBarBehavior.floating),
                  );
                  context.read<AuthBloc>().add(LogoutRequestedEvent());
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: const Color(0xFFE53935),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Confirmer la suppression'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Confidentialité & RGPD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textDark)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textDark),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Erreur: $_errorMessage'),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadAll, child: const Text('Réessayer')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Badge RGPD & Chiffrement
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00897B), Color(0xFF26A69A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Protection Données de Santé',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.white),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Chiffrement AES-256 local & conformité stricte RGPD Art. 9',
                                    style: TextStyle(fontSize: 11.5, color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Section 1 : Préférences de confidentialité
                      _buildSectionCard(
                        title: 'Paramètres de protection',
                        icon: Icons.lock_outline_rounded,
                        children: [
                          _buildSwitch(
                            title: 'Partage de recherche anonymisé (Opt-in)',
                            subtitle: 'Contribuer à la recherche statistique sans aucun identifiant direct',
                            value: _settings?.partageDonneesRecherche ?? false,
                            onChanged: (v) {
                              _updateSetting(
                                UserPrivacySettingsModel(
                                  partageDonneesRecherche: v,
                                  notificationsActivees: _settings?.notificationsActivees ?? true,
                                  verrouillageBiometrique: _settings?.verrouillageBiometrique ?? false,
                                  masquageDonneesSensibles: _settings?.masquageDonneesSensibles ?? false,
                                ),
                              );
                            },
                          ),
                          const Divider(color: AppTheme.borderLight, height: 1),
                          _buildSwitch(
                            title: 'Notifications et rappels push',
                            subtitle: 'Alertes discrètes de fenêtre fertile et de début de cycle',
                            value: _settings?.notificationsActivees ?? true,
                            onChanged: (v) {
                              _updateSetting(
                                UserPrivacySettingsModel(
                                  partageDonneesRecherche: _settings?.partageDonneesRecherche ?? false,
                                  notificationsActivees: v,
                                  verrouillageBiometrique: _settings?.verrouillageBiometrique ?? false,
                                  masquageDonneesSensibles: _settings?.masquageDonneesSensibles ?? false,
                                ),
                              );
                            },
                          ),
                          const Divider(color: AppTheme.borderLight, height: 1),
                          _buildSwitch(
                            title: 'Verrouillage biométrique (FaceID / TouchID)',
                            subtitle: 'Exiger une authentification à l\'ouverture de l\'application',
                            value: _settings?.verrouillageBiometrique ?? false,
                            onChanged: (v) {
                              _updateSetting(
                                UserPrivacySettingsModel(
                                  partageDonneesRecherche: _settings?.partageDonneesRecherche ?? false,
                                  notificationsActivees: _settings?.notificationsActivees ?? true,
                                  verrouillageBiometrique: v,
                                  masquageDonneesSensibles: _settings?.masquageDonneesSensibles ?? false,
                                ),
                              );
                            },
                          ),
                          const Divider(color: AppTheme.borderLight, height: 1),
                          _buildSwitch(
                            title: 'Masquage en arrière-plan',
                            subtitle: 'Flouter l\'application dans le sélecteur multitâche',
                            value: _settings?.masquageDonneesSensibles ?? false,
                            onChanged: (v) {
                              _updateSetting(
                                UserPrivacySettingsModel(
                                  partageDonneesRecherche: _settings?.partageDonneesRecherche ?? false,
                                  notificationsActivees: _settings?.notificationsActivees ?? true,
                                  verrouillageBiometrique: _settings?.verrouillageBiometrique ?? false,
                                  masquageDonneesSensibles: v,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Section 2 : Consentements certifiés
                      _buildSectionCard(
                        title: 'Historique des consentements',
                        icon: Icons.history_edu_rounded,
                        children: [
                          if (_consents.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Aucun consentement spécifique enregistré.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            )
                          else
                            ..._consents.map(
                              (c) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      c.accepte ? Icons.check_circle_rounded : Icons.cancel_outlined,
                                      color: c.accepte ? Colors.teal : Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _formatConsentName(c.typeConsentement),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
                                          ),
                                          Text('Version ${c.versionDocument} • Date: ${c.dateConsentement?.substring(0, 10) ?? "N/A"}',
                                              style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: (c.accepte ? Colors.teal : Colors.grey).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        c.accepte ? 'Accordé' : 'Retiré',
                                        style: TextStyle(
                                          color: c.accepte ? Colors.teal : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Section 3 : Sessions Actives
                      _buildSectionCard(
                        title: 'Appareils & Sessions actives',
                        icon: Icons.devices_rounded,
                        children: [
                          if (_sessions.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Session courante uniquement.', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            )
                          else
                            ..._sessions.map(
                              (sess) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    const Icon(Icons.phone_android_rounded, size: 20, color: AppTheme.primary),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(sess.nomAppareil, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                                          Text('Connecté le ${sess.dateConnexion.substring(0, 10)}', style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => _revokeSession(sess.id),
                                      style: TextButton.styleFrom(foregroundColor: const Color(0xFFE53935)),
                                      child: const Text('Déconnecter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Section 4 : Droit à l'effacement (Zone de danger)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFCDD2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, color: Color(0xFFD32F2F), size: 20),
                                SizedBox(width: 8),
                                Text('Droit à l\'effacement RGPD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFD32F2F))),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Supprimez définitivement votre compte et l\'ensemble de vos historiques de cycle et prédictions de fertilité.',
                              style: TextStyle(fontSize: 12, color: AppTheme.textDark, height: 1.4),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton(
                              onPressed: _showDeleteAccountDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD32F2F),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              child: const Text('Demander la suppression de mon compte', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  String _formatConsentName(String code) {
    switch (code) {
      case 'cgu':
        return 'Conditions Générales d\'Utilisation';
      case 'politique_confidentialite':
        return 'Politique de Confidentialité';
      case 'traitement_donnees_sante':
        return 'Traitement des Données de Cycle';
      case 'partage_donnees_anonymisees':
        return 'Recherche Médicale Anonymisée';
      default:
        return code.toUpperCase();
    }
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primary),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: AppTheme.textDark)),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: AppTheme.primary,
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
