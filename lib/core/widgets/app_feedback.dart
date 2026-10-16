import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../error/api_exception.dart';
import '../theme/app_theme.dart';

/// Types de retour visuel pour l'expérience utilisateur
enum FeedbackType {
  success,
  error,
  warning,
  info,
}

/// Système professionnel, moderne et bienveillant de notifications et d'alertes
/// Respecte l'identité visuelle FertiliteApp (AppTheme) et propose des retours haptiques subtils.
class AppFeedback {
  AppFeedback._();

  // ==========================================
  // 1. MESSAGES DE SUCCÈS (Toast Flottant)
  // ==========================================

  /// Affiche une notification de succès valorisante et soignée
  static void showSuccess(
    BuildContext context, {
    required String message,
    String title = 'Succès',
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    HapticFeedback.lightImpact();

    _showToast(
      context,
      type: FeedbackType.success,
      title: title,
      message: message,
      icon: Icons.check_circle_rounded,
      accentColor: const Color(0xFF10B981), // Émeraude douce
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  // ==========================================
  // 2. MESSAGES D'ERREUR (Toast Flottant)
  // ==========================================

  /// Affiche une notification d'erreur compréhensible avec suggestion d'action
  static void showError(
    BuildContext context, {
    dynamic error,
    String? title,
    String? message,
    String? customTitle,
    String? customMessage,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 5),
  }) {
    HapticFeedback.mediumImpact();

    final effectiveError = error ?? customMessage ?? message ?? 'Une erreur est survenue';
    final apiException = ApiException.from(effectiveError);
    final resolvedTitle = customTitle ?? title ?? apiException.title;
    final resolvedMessage = customMessage ?? message ?? apiException.userFriendlyMessage;
    final suggestion = apiException.actionSuggestion;
    final iconData = _resolveErrorIcon(apiException.errorCode);
    final isColdStart = apiException.isServerWakingUp;

    _showToast(
      context,
      type: isColdStart ? FeedbackType.warning : FeedbackType.error,
      title: resolvedTitle,
      message: resolvedMessage,
      suggestion: suggestion,
      icon: isColdStart ? Icons.cloud_sync_rounded : iconData,
      accentColor: isColdStart
          ? const Color(0xFFF59E0B) // Ambre doux
          : const Color(0xFFF43F5E), // Rose corail santé
      actionLabel: actionLabel,
      onAction: onAction,
      duration: isColdStart ? const Duration(seconds: 8) : duration,
    );
  }

  // ==========================================
  // 3. AVERTISSEMENTS & INFOS
  // ==========================================

  /// Affiche un avertissement non bloquant (ex: validation avant soumission)
  static void showWarning(
    BuildContext context, {
    required String message,
    String title = 'Attention',
    String? suggestion,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    HapticFeedback.selectionClick();

    _showToast(
      context,
      type: FeedbackType.warning,
      title: title,
      message: message,
      suggestion: suggestion,
      icon: Icons.warning_amber_rounded,
      accentColor: const Color(0xFFF59E0B),
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  /// Affiche une note informative ou un conseil bien-être
  static void showInfo(
    BuildContext context, {
    required String message,
    String title = 'Information',
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    HapticFeedback.selectionClick();

    _showToast(
      context,
      type: FeedbackType.info,
      title: title,
      message: message,
      icon: Icons.info_outline_rounded,
      accentColor: AppTheme.accentRose,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  // ==========================================
  // 4. DIALOGUE MODAL DE SUCCÈS MAJEUR
  // ==========================================

  /// Affiche une fenêtre modale célébrant une étape clé (Inscription réussie, Cycle créé, etc.)
  static Future<void> showSuccessDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Commencer',
    VoidCallback? onConfirm,
  }) {
    HapticFeedback.heavyImpact();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Halo animé avec icône de célébration
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF34D399)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      onConfirm?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // 5. MODALE DE CONFIRMATION ERGONOMIQUE
  // ==========================================

  /// Affiche une modale de confirmation ergonomique avant une action sensible ou destructive
  /// (ex: supprimer un cycle, déclarer un nouveau cycle, abandonner une saisie)
  static Future<bool> showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmer',
    String cancelLabel = 'Annuler',
    IconData icon = Icons.help_outline_rounded,
    Color? confirmColor,
    bool isDestructive = false,
  }) async {
    HapticFeedback.mediumImpact();

    final Color actionColor = confirmColor ??
        (isDestructive ? const Color(0xFFE11D48) : AppTheme.primary);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: actionColor.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Halo avec icône thématique
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: actionColor.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    icon,
                    color: actionColor,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.textMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),
                // Deux boutons ergonomiques (Annuler / Confirmer)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(ctx).pop(false);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textMuted,
                          side: const BorderSide(color: AppTheme.borderLight, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          cancelLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(ctx).pop(true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: actionColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    return result ?? false;
  }

  // ==========================================
  // IMPLÉMENTATION INTERNE DU TOAST FLOTTANT
  // ==========================================

  static void _showToast(
    BuildContext context, {
    required FeedbackType type,
    required String title,
    required String message,
    String? suggestion,
    required IconData icon,
    required Color accentColor,
    String? actionLabel,
    VoidCallback? onAction,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: accentColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        // Fond sombre obsidian noble pour faire ressortir les informations
        backgroundColor: const Color(0xFF1E293B),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge d'icône avec halo lumineux
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: accentColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Textes : Titre + Message + Suggestion éventuelle
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.35,
                    ),
                  ),
                  if (suggestion != null &&
                      suggestion.isNotEmpty &&
                      !message.contains(suggestion)) ...[
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

            // Action interactive (ex: "Réessayer", "Se connecter")
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  onAction();
                },
                style: TextButton.styleFrom(
                  foregroundColor: accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: accentColor.withValues(alpha: 0.4)),
                  ),
                ),
                child: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _resolveErrorIcon(String errorCode) {
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

/// Bandeau d'alerte en ligne intégrable directement dans les formulaires (Login, Register, etc.)
class InlineFeedbackBanner extends StatelessWidget {
  final FeedbackType type;
  final String title;
  final String message;
  final String? suggestion;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  const InlineFeedbackBanner({
    super.key,
    required this.type,
    required this.title,
    required this.message,
    this.suggestion,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color accentColor;
    IconData icon;

    switch (type) {
      case FeedbackType.success:
        bgColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFFA7F3D0);
        accentColor = const Color(0xFF059669);
        icon = Icons.check_circle_rounded;
        break;
      case FeedbackType.warning:
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFDE68A);
        accentColor = const Color(0xFFD97706);
        icon = Icons.warning_amber_rounded;
        break;
      case FeedbackType.info:
        bgColor = AppTheme.primaryLight.withValues(alpha: 0.5);
        borderColor = AppTheme.borderLight;
        accentColor = AppTheme.primary;
        icon = Icons.info_outline_rounded;
        break;
      case FeedbackType.error:
        bgColor = const Color(0xFFFFF1F2);
        borderColor = const Color(0xFFFECDD3);
        accentColor = const Color(0xFFE11D48);
        icon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textDark,
                    height: 1.35,
                  ),
                ),
                if (suggestion != null && suggestion!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '💡 $suggestion',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: onAction,
                    child: Text(
                      actionLabel!,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 18, color: accentColor),
              ),
            ),
        ],
      ),
    );
  }
}
