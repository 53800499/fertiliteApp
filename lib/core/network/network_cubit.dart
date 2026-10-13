import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'network_state.dart';

class NetworkCubit extends Cubit<NetworkState> {
  final Dio? dio;
  Timer? _reconnectFlashTimer;
  Timer? _periodicOfflineTimer;

  NetworkCubit({this.dio})
      : super(NetworkState(lastChecked: DateTime.now()));

  void setOffline() {
    if (!state.isOnline) return;

    _reconnectFlashTimer?.cancel();
    emit(state.copyWith(
      isOnline: false,
      isChecking: false,
      wasOffline: false,
      lastChecked: DateTime.now(),
    ));

    // Lancer une vérification périodique toutes les 15 secondes pour rétablir dès que possible
    _startPeriodicOfflineCheck();
  }

  void setOnline() {
    if (state.isOnline && !state.wasOffline) return;

    _periodicOfflineTimer?.cancel();
    _reconnectFlashTimer?.cancel();

    final hadBeenOffline = !state.isOnline;

    emit(state.copyWith(
      isOnline: true,
      isChecking: false,
      wasOffline: hadBeenOffline,
      lastChecked: DateTime.now(),
    ));

    if (hadBeenOffline) {
      // Effacer l'indicateur de reconnexion après 4 secondes
      _reconnectFlashTimer = Timer(const Duration(seconds: 4), () {
        if (!isClosed) {
          emit(state.copyWith(wasOffline: false));
        }
      });
    }
  }

  Future<bool> checkConnectivity({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(isChecking: true));
    }

    bool online = false;

    // 1. Essai de résolution DNS (mobile/desktop natif)
    if (!kIsWeb) {
      try {
        final result = await InternetAddress.lookup('dns.google')
            .timeout(const Duration(seconds: 3));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          online = true;
        }
      } catch (_) {
        online = false;
      }
    }

    // 2. Si le DNS natif échoue ou en mode web, tester une requête HTTP rapide
    if (!online && dio != null) {
      try {
        final response = await dio!.get(
          'https://clients3.google.com/generate_204',
          options: Options(
            responseType: ResponseType.plain,
            sendTimeout: const Duration(seconds: 3),
            receiveTimeout: const Duration(seconds: 3),
          ),
        );
        if (response.statusCode == 204 || response.statusCode == 200) {
          online = true;
        }
      } catch (_) {
        online = false;
      }
    }

    if (online) {
      setOnline();
    } else {
      setOffline();
    }

    return online;
  }

  void _startPeriodicOfflineCheck() {
    _periodicOfflineTimer?.cancel();
    _periodicOfflineTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!state.isOnline) {
        checkConnectivity(silent: true);
      } else {
        _periodicOfflineTimer?.cancel();
      }
    });
  }

  @override
  Future<void> close() {
    _reconnectFlashTimer?.cancel();
    _periodicOfflineTimer?.cancel();
    return super.close();
  }
}
