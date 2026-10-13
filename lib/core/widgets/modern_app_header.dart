import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../network/network_cubit.dart';
import '../theme/app_theme.dart';

/// Header moderne, épuré et professionnel aux standards d'applications de santé haut de gamme
class ModernAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onRefresh;
  final bool showNetworkStatus;

  const ModernAppHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.onRefresh,
    this.showNetworkStatus = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderLight, width: 1.0),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 14),
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
                          Text(
                            subtitle!.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accentRose,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
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
                    const SizedBox(width: 8),
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
            try {
              BlocProvider.of<NetworkCubit>(ctx).checkConnectivity();
            } catch (_) {}
          },
          child: Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFCCBC), width: 1),
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
                const SizedBox(width: 5),
                const Text(
                  'Hors ligne',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFBF360C),
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

/// Bouton d'action standardisé et moderne pour les headers
class ModernHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? iconColor;

  const ModernHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEDE5EC), width: 1),
            ),
            child: Icon(
              icon,
              size: 19,
              color: iconColor ?? AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }
}
