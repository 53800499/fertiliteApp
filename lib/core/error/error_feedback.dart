import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'api_exception.dart';

/// Composants et utilitaires pour afficher les erreurs de manière claire,
/// bienveillante et compréhensible par l'utilisatrice
class AppErrorFeedback {
  AppErrorFeedback._();

  /// Affiche une SnackBar élégante et explicite
  static void showSnackBar(
    BuildContext context, {
    required dynamic error,
    String? customTitle,
    String? customMessage,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 5),
  }) {
    final apiException = ApiException.from(error);
    final title = customTitle ?? apiException.title;
    final message = customMessage ?? apiException.userFriendlyMessage;
    final suggestion = apiException.actionSuggestion;

    final iconData = _resolveIcon(apiException.errorCode);
    final isColdStart = apiException.isServerWakingUp;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: isColdStart ? const Duration(seconds: 8) : duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF2C2438), // Fond sombre améthyste profond et apaisant
        elevation: 6,
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isColdStart ? Colors.amber.withValues(alpha: 0.2) : const Color(0xFFEF5350).withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: isColdStart ? Colors.amberAccent : const Color(0xFFFF8A80),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.3,
                    ),
                  ),
                  if (suggestion.isNotEmpty && !message.contains(suggestion)) ...[
                    const SizedBox(height: 4),
                    Text(
                      '💡 $suggestion',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: AppTheme.accentRose,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  static IconData _resolveIcon(String errorCode) {
    switch (errorCode) {
      case 'SERVER_WAKING_UP':
        return Icons.cloud_sync_rounded;
      case 'NETWORK_OFFLINE':
        return Icons.wifi_off_rounded;
      case 'INVALID_CREDENTIALS':
        return Icons.lock_outline_rounded;
      case 'EMAIL_ALREADY_EXISTS':
        return Icons.account_circle_outlined;
      case 'AUTH_UNDERAGE':
        return Icons.cake_rounded;
      case 'AUTH_CONSENTS_REQUIRED':
        return Icons.assignment_late_outlined;
      case 'RATE_LIMITED':
        return Icons.hourglass_top_rounded;
      case 'ACCOUNT_SUSPENDED':
        return Icons.block_rounded;
      case 'AUTH_SESSION_EXPIRED':
        return Icons.timer_outlined;
      default:
        return Icons.info_outline_rounded;
    }
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
