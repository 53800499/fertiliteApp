import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/error_feedback.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/auth_models.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  DateTime? _selectedBirthDate;
  bool _obscurePassword = true;

  // Consentements obligatoires & optionnel
  bool _consentCgu = true;
  bool _consentPrivacy = true;
  bool _consentHealth = true;
  bool _consentResearch = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 24, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime(now.year - 12, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedBirthDate == null) {
      AppErrorFeedback.showSnackBar(
        context,
        error: 'Veuillez renseigner votre date de naissance.',
        customTitle: 'Date de naissance requise',
      );
      return;
    }

    final today = DateTime.now();
    int age = today.year - _selectedBirthDate!.year;
    if (today.month < _selectedBirthDate!.month ||
        (today.month == _selectedBirthDate!.month && today.day < _selectedBirthDate!.day)) {
      age--;
    }
    if (age < 12) {
      AppErrorFeedback.showSnackBar(
        context,
        error: 'L\'application est réservée aux personnes âgées d\'au moins 12 ans conformément aux règles de protection des données de santé.',
        customTitle: 'Âge minimum requis (12 ans)',
      );
      return;
    }

    if (!_consentCgu || !_consentPrivacy || !_consentHealth) {
      AppErrorFeedback.showSnackBar(
        context,
        error: 'Pour créer votre compte et protéger vos données de santé, l\'acceptation des CGU, de la politique de confidentialité et du traitement des données est obligatoire.',
        customTitle: 'Consentements obligatoires requis',
      );
      return;
    }

    final formattedBirthDate =
        "${_selectedBirthDate!.year.toString().padLeft(4, '0')}-${_selectedBirthDate!.month.toString().padLeft(2, '0')}-${_selectedBirthDate!.day.toString().padLeft(2, '0')}";

    final request = RegisterRequestModel(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      birthDate: formattedBirthDate,
      preferredLanguage: 'fr',
      timezone: 'Africa/Porto-Novo',
      consents: [
        ConsentItemModel(type: 'cgu', version: '1.0', accepted: _consentCgu),
        ConsentItemModel(type: 'politique_confidentialite', version: '1.0', accepted: _consentPrivacy),
        ConsentItemModel(type: 'entrainement_ml', version: '1.0', accepted: _consentHealth),
        ConsentItemModel(type: 'partage_donnees_anonymisees', version: '1.0', accepted: _consentResearch),
      ],
    );

    context.read<AuthBloc>().add(RegisterRequestedEvent(request));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Créer mon compte', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppTheme.textDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textDark),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailureState) {
            AppErrorFeedback.showSnackBar(
              context,
              error: state.exception ?? state.errorMessage,
              customTitle: state.title,
              actionLabel: state.errorCode == 'EMAIL_ALREADY_EXISTS'
                  ? 'Se connecter'
                  : (state.isServerWakingUp ? 'Réessayer' : null),
              onAction: state.errorCode == 'EMAIL_ALREADY_EXISTS'
                  ? () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  : (state.isServerWakingUp ? _submit : null),
            );
          } else if (state is AuthenticatedState) {
            Navigator.pop(context);
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Titre & Sous-titre
                      const Text(
                        'Bienvenue sur FertiliteApp',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Vos données restent confidentielles et chiffrées au repos.',
                        style: TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 16),

                      // Bandeau d'erreur explicatif en tête de formulaire
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is AuthFailureState) {
                            return AppErrorBanner(
                              error: state.exception ?? state.errorMessage,
                              title: state.title,
                              message: state.errorMessage,
                              actionLabel: state.errorCode == 'EMAIL_ALREADY_EXISTS'
                                  ? 'Un compte existe déjà. Se connecter ?'
                                  : (state.isServerWakingUp ? 'Réessayer' : null),
                              onAction: state.errorCode == 'EMAIL_ALREADY_EXISTS'
                                  ? () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                                      );
                                    }
                                  : (state.isServerWakingUp ? _submit : null),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 12),

                      // Étape 1 : Identifiants
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderLight),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppTheme.primaryLight,
                                  child: Text('1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                ),
                                SizedBox(width: 10),
                                Text('Identifiants de connexion', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                hintText: 'ex: jeanne@example.com',
                                prefixIcon: Icon(Icons.mail_outline_rounded, color: AppTheme.primary, size: 20),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Email obligatoire';
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val.trim())) return 'Format d\'email invalide';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe (8 caractères min)',
                                prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primary, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Mot de passe obligatoire';
                                if (val.length < 8) return 'Au moins 8 caractères';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscurePassword,
                              decoration: const InputDecoration(
                                labelText: 'Confirmer le mot de passe',
                                prefixIcon: Icon(Icons.lock_clock_outlined, color: AppTheme.primary, size: 20),
                              ),
                              validator: (val) {
                                if (val != _passwordController.text) return 'Les mots de passe ne correspondent pas';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Étape 2 : Date de naissance & Majorité
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderLight),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppTheme.primaryLight,
                                  child: Text('2', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                ),
                                SizedBox(width: 10),
                                Text('Informations physiologiques', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                                decoration: BoxDecoration(
                                  color: AppTheme.background,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppTheme.borderLight),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.cake_rounded, color: AppTheme.accentRose, size: 22),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Date de naissance', style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted)),
                                          const SizedBox(height: 2),
                                          Text(
                                            _selectedBirthDate == null
                                                ? 'Sélectionner votre date'
                                                : '${_selectedBirthDate!.day.toString().padLeft(2, '0')}/${_selectedBirthDate!.month.toString().padLeft(2, '0')}/${_selectedBirthDate!.year}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: _selectedBirthDate == null ? AppTheme.textLight : AppTheme.textDark,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.calendar_month_rounded, color: AppTheme.primary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Étape 3 : Consentements RGPD interactifs
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.borderLight),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppTheme.primaryLight,
                                  child: Text('3', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                                ),
                                SizedBox(width: 10),
                                Text('Consentements légaux & RGPD', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildConsentCard(
                              title: 'Conditions Générales (CGU)*',
                              subtitle: 'Acceptation du cadre d\'utilisation du service',
                              value: _consentCgu,
                              onChanged: (v) => setState(() => _consentCgu = v),
                            ),
                            _buildConsentCard(
                              title: 'Politique de Confidentialité*',
                              subtitle: 'Chiffrement et protection de la vie privée',
                              value: _consentPrivacy,
                              onChanged: (v) => setState(() => _consentPrivacy = v),
                            ),
                            _buildConsentCard(
                              title: 'Traitement données de cycle*',
                              subtitle: 'Calculs physiologiques d\'estimation fertile',
                              value: _consentHealth,
                              onChanged: (v) => setState(() => _consentHealth = v),
                            ),
                            _buildConsentCard(
                              title: 'Recherche anonymisée (Optionnel)',
                              subtitle: 'Amélioration statistique des algorithmes',
                              value: _consentResearch,
                              onChanged: (v) => setState(() => _consentResearch = v),
                              isOptional: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Bouton de validation
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoadingState;
                          return Container(
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: AppTheme.floatingShadow,
                            ),
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 17),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                    )
                                  : const Text('Créer mon compte', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // Déjà un compte
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Déjà inscrite ? ', style: TextStyle(color: AppTheme.textMuted, fontSize: 13.5)),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            child: const Text(
                              'Se connecter',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsentCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isOptional = false,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? AppTheme.primary : AppTheme.borderLight,
                  width: 1.5,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: value ? AppTheme.textDark : AppTheme.textMuted,
                    ),
                  ),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
