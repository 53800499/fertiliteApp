import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../network/network_cubit.dart';
import '../theme/app_theme.dart';

/// Header moderne, épuré et ultra-professionnel aux standards d'applications de santé haut de gamme (FEMAX)
class ModernAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onRefresh;
  final bool showNetworkStatus;
  final bool transparent;
  final Color? backgroundColor;

  const ModernAppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.onRefresh,
    this.showNetworkStatus = true,
    this.transparent = false,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && Navigator.canPop(context)) {
      effectiveLeading = ModernHeaderIconButton(
        icon: Icons.arrow_back_ios_new_rounded,
        tooltip: 'Retour',
        iconSize: 17,
        onPressed: () {
          HapticFeedback.selectionClick();
          Navigator.maybePop(context);
        },
      );
    }

    Widget headerContent = Container(
      decoration: BoxDecoration(
        color: backgroundColor ??
            (transparent
                ? Colors.white.withValues(alpha: 0.82)
                : Colors.white.withValues(alpha: 0.96)),
        border: Border(
          bottom: BorderSide(
            color: transparent
                ? AppTheme.primary.withValues(alpha: 0.08)
                : AppTheme.borderLight.withValues(alpha: 0.8),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Row(
            children: [
              if (effectiveLeading != null) ...[
                effectiveLeading,
                const SizedBox(width: 12),
              ],
              // Titre & Sous-titre hiérarchisé
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: const BoxDecoration(
                              color: AppTheme.accentRose,
                              shape: BoxShape.circle,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              subtitle!.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accentRose,
                                letterSpacing: 1.15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Actions & État réseau
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showNetworkStatus) _buildNetworkBadge(context),
                  if (onRefresh != null) ...[
                    const SizedBox(width: 6),
                    ModernHeaderIconButton(
                      icon: Icons.refresh_rounded,
                      tooltip: 'Actualiser',
                      onPressed: onRefresh!,
                    ),
                  ],
                  if (actions != null) ...actions!,
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (transparent) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
          child: headerContent,
        ),
      );
    }

    return headerContent;
  }

  Widget _buildNetworkBadge(BuildContext context) {
    return Builder(
      builder: (ctx) {
        bool isOffline = false;
        try {
          isOffline = !BlocProvider.of<NetworkCubit>(ctx).state.isOnline;
        } catch (_) {}

        if (!isOffline) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            try {
              BlocProvider.of<NetworkCubit>(ctx).checkConnectivity();
            } catch (_) {}
          },
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFB74D).withValues(alpha: 0.5), width: 1),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE65100).withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE65100),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Hors ligne',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBF360C),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Bouton d'action standardisé, raffiné et haptique pour les headers FEMAX
class ModernHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? iconColor;
  final double iconSize;

  const ModernHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor,
    this.iconSize = 19,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onPressed();
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.85), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.035),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor ?? AppTheme.textDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
