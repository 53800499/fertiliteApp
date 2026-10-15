import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_theme.dart';

class ModernNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const ModernNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Barre de navigation inférieure haut de gamme : fluide, tactile, moderne et rigoureusement professionnelle
class ModernFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<ModernNavItem> items;
  final bool isOffline;

  const ModernFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    const topRadius = Radius.circular(24.0);
    const topBorderRadius = BorderRadius.vertical(top: topRadius);

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: topBorderRadius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: topBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: topBorderRadius,
              border: Border.all(
                color: isOffline
                    ? const Color(0xFFEF5350).withValues(alpha: 0.4)
                    : const Color(0xFFEDE5EC),
                width: 1.0,
              ),
            ),
            child: SafeArea(
              top: false,
            child: SizedBox(
              height: 66,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tabWidth = constraints.maxWidth / items.length;

                  return Stack(
                    children: [
                      // 1. Indicateur fluide supérieur (glisse en continu entre les onglets)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        left: currentIndex * tabWidth + (tabWidth - 36) / 2,
                        top: 0,
                        width: 36,
                        height: 3,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. Capsule lumineuse coulissante derrière l'icône active
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        left: currentIndex * tabWidth + (tabWidth - 58) / 2,
                        top: 8,
                        width: 58,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFF3E5F5).withValues(alpha: 0.9),
                                const Color(0xFFFCE4EC).withValues(alpha: 0.9),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.accentRose.withValues(alpha: 0.3),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 3. Rangée des boutons d'onglets avec micro-animations
                      Row(
                        children: List.generate(items.length, (index) {
                          final item = items[index];
                          final isSelected = currentIndex == index;

                          return Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (!isSelected) {
                                    HapticFeedback.selectionClick();
                                    onTap(index);
                                  }
                                },
                                highlightColor: Colors.transparent,
                                splashColor: AppTheme.primaryLight.withValues(alpha: 0.3),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 4),

                                    // Icône avec rebond élastique subtil
                                    AnimatedScale(
                                      scale: isSelected ? 1.14 : 1.0,
                                      duration: const Duration(milliseconds: 240),
                                      curve: Curves.easeOutBack,
                                      child: Icon(
                                        isSelected ? item.selectedIcon : item.icon,
                                        size: 22,
                                        color: isSelected
                                            ? AppTheme.primary
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),

                                    const SizedBox(height: 5),

                                    // Libellé de l'onglet
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(milliseconds: 200),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                        color: isSelected
                                            ? AppTheme.primaryDark
                                            : const Color(0xFF64748B),
                                        letterSpacing: isSelected ? -0.2 : -0.1,
                                      ),
                                      child: Text(
                                        item.label,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
}
