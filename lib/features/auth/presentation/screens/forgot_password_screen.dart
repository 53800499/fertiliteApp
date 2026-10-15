import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/error_feedback.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            ForgotPasswordRequestedEvent(_emailController.text.trim()),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryAmethyst = Color(0xFF8E24AA);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F9),
      appBar: AppBar(
        title: const Text('Mot de passe oublié', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF37474F),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailureState) {
            AppFeedback.showError(
              context,
              error: state.exception ?? state.errorMessage,
              customTitle: state.title,
              actionLabel: state.isServerWakingUp ? 'Réessayer' : null,
              onAction: state.isServerWakingUp ? _submit : null,
            );
          } else if (state is ForgotPasswordSuccessState) {
            AppFeedback.showSuccess(
              context,
              title: 'Email expédié 📬',
              message: 'Un lien de réinitialisation sécurisé vous a été envoyé.',
            );
          }
        },
        builder: (context, state) {
          final isSuccess = state is ForgotPasswordSuccessState;
          final isLoading = state is AuthLoadingState;

          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: isSuccess
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(Icons.mark_email_read_rounded, size: 60, color: Colors.teal.shade700),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Email envoyé avec succès',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF37474F)),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
                            ),
                            const SizedBox(height: 30),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryAmethyst,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Retour à la connexion'),
                            ),
                          ],
                        )
                      : Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (state is AuthFailureState)
                                AppErrorBanner(
                                  error: state.exception ?? state.errorMessage,
                                  title: state.title,
                                  message: state.errorMessage,
                                  actionLabel: state.isServerWakingUp ? 'Réessayer' : null,
                                  onAction: state.isServerWakingUp ? _submit : null,
                                ),
                              const Icon(Icons.lock_reset_rounded, size: 64, color: primaryAmethyst),
                              const SizedBox(height: 16),
                              const Text(
                                'Récupérer l\'accès à votre compte',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF37474F)),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Saisissez l\'email associé à votre compte. Si un compte existe, nous vous enverrons les instructions sécurisées.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                              ),
                              const SizedBox(height: 28),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Adresse email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) return 'Email requis';
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Format d\'email non valide';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: isLoading ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryAmethyst,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                      )
                                    : const Text('Envoyer le lien de réinitialisation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
