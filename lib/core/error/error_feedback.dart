import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_feedback.dart';
import 'api_exception.dart';

export '../widgets/app_feedback.dart';

/// Composants et utilitaires pour afficher les erreurs de manière claire,
/// bienveillante et compréhensible par l'utilisatrice
class AppErrorFeedback {
  AppErrorFeedback._();

  /// Affiche une SnackBar élégante et explicite (délègue vers AppFeedback)
  static void showSnackBar(
    BuildContext context, {
    required dynamic error,
    String? customTitle,
    String? customMessage,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 5),
  }) {
    AppFeedback.showError(
      context,
      error: error,
      customTitle: customTitle,
      customMessage: customMessage,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Affiche une SnackBar de succès valorisante
  static void showSuccess(
    BuildContext context, {
    required String message,
    String title = 'Succès',
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    AppFeedback.showSuccess(
      context,
      message: message,
      title: title,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }
}

/// Bandeau visuel d'erreur ou d'avertissement insérable dans un formulaire
class AppErrorBanner extends StatelessWidget {
  final dynamic error;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppErrorBanner({
    super.key,
    required this.error,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (error == null && message == null) return const SizedBox.shrink();

    final apiException = ApiException.from(error);
    final displayTitle = title ?? apiException.title;
    final displayMessage = message ?? apiException.userFriendlyMessage;
    final suggestion = apiException.actionSuggestion;
    final isWarning = apiException.isServerWakingUp;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFF8E1) : const Color(0xFFFBE9E7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWarning ? const Color(0xFFFFE082) : const Color(0xFFFFCCBC),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning ? Icons.cloud_sync_rounded : Icons.info_rounded,
            color: isWarning ? const Color(0xFFF57F17) : const Color(0xFFD84315),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: isWarning ? const Color(0xFFE65100) : const Color(0xFFBF360C),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  displayMessage,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: isWarning ? const Color(0xFF5D4037) : const Color(0xFF4E342E),
                    height: 1.35,
                  ),
                ),
                if (suggestion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '💡 $suggestion',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: isWarning ? const Color(0xFF6D4C41) : const Color(0xFF5D4037),
                    ),
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onAction,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        actionLabel!,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isWarning ? const Color(0xFFE65100) : AppTheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Vue de remplacement complète lors d'une erreur de chargement
class AppErrorEmptyView extends StatelessWidget {
  final dynamic error;
  final VoidCallback onRetry;
  final String? customTitle;
  final String? customMessage;

  const AppErrorEmptyView({
    super.key,
    required this.error,
    required this.onRetry,
    this.customTitle,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final apiException = ApiException.from(error);
    final title = customTitle ?? apiException.title;
    final message = customMessage ?? apiException.userFriendlyMessage;
    final suggestion = apiException.actionSuggestion;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                shape: BoxShape.circle,
                boxShadow: AppTheme.softShadow,
              ),
              child: Icon(
                apiException.isServerWakingUp ? Icons.cloud_sync_rounded : Icons.spa_outlined,
                size: 40,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
            if (suggestion.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Text(
                  '💡 $suggestion',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
