import 'package:flutter/material.dart';

/// Puce discrète indiquant qu'un contenu ou écran est affiché à partir des données locales hors-ligne
class OfflineBadgeChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const OfflineBadgeChip({
    super.key,
    this.label = 'Données locales (hors ligne)',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFCCBC), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFFE65100),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.cloud_off_rounded,
              size: 13,
              color: Color(0xFFE65100),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFBF360C),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
