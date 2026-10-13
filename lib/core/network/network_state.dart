import 'package:equatable/equatable.dart';

class NetworkState extends Equatable {
  final bool isOnline;
  final bool isChecking;
  final bool wasOffline;
  final DateTime lastChecked;

  const NetworkState({
    this.isOnline = true,
    this.isChecking = false,
    this.wasOffline = false,
    required this.lastChecked,
  });

  NetworkState copyWith({
    bool? isOnline,
    bool? isChecking,
    bool? wasOffline,
    DateTime? lastChecked,
  }) {
    return NetworkState(
      isOnline: isOnline ?? this.isOnline,
      isChecking: isChecking ?? this.isChecking,
      wasOffline: wasOffline ?? this.wasOffline,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }

  @override
  List<Object?> get props => [isOnline, isChecking, wasOffline, lastChecked];
}
