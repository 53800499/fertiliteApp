import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../network_cubit.dart';
import '../network_state.dart';

/// Bandeau flottant discret, animé et élégant informant de l'état de la connexion
class GlobalOfflineBanner extends StatelessWidget {
  const GlobalOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, state) {
        final isOffline = !state.isOnline;
        final wasOffline = state.wasOffline;

        if (!isOffline && !wasOffline) {
          return const SizedBox.shrink();
        }

        final isReconnected = wasOffline && !isOffline;

        return SafeArea(
          bottom: false,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: isReconnected
                ? const LinearGradient(
                    colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFFFF3E0), Color(0xFFFFEBEE)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isReconnected
                  ? const Color(0xFFA5D6A7)
                  : const Color(0xFFFFCCBC),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isReconnected ? Colors.green : Colors.deepOrange)
                    .withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Indicateur visuel à impulsion
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isReconnected
                      ? const Color(0xFF2E7D32).withValues(alpha: 0.12)
                      : const Color(0xFFE65100).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isReconnected
                      ? Icons.check_circle_rounded
                      : Icons.wifi_off_rounded,
                  size: 18,
                  color: isReconnected
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFE65100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isReconnected
                          ? 'Connexion rétablie'
                          : 'Mode hors ligne actif',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isReconnected
                            ? const Color(0xFF1B5E20)
                            : const Color(0xFFBF360C),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isReconnected
                          ? 'Vos données sont synchronisées avec le serveur.'
                          : 'Vos données locales restent consultables en toute sécurité.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isReconnected
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFF6D4C41),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isReconnected) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: state.isChecking
                      ? null
                      : () => context.read<NetworkCubit>().checkConnectivity(),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(
                        color: Color(0xFFFFCCBC),
                        width: 1,
                      ),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: state.isChecking
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE65100),
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.refresh_rounded,
                              size: 13,
                              color: Color(0xFFE65100),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Vérifier',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ],
          ),
        ),
      );
      },
    );
  }
}
