import '../network/network_cubit.dart';
import '../network/api_client.dart';
import '../security/secure_storage_helper.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/users/data/datasources/user_remote_data_source.dart';
import '../../features/users/data/repositories/user_repository_impl.dart';
import '../../features/users/domain/repositories/user_repository.dart';
import '../../features/privacy/data/datasources/privacy_remote_data_source.dart';
import '../../features/privacy/data/repositories/privacy_repository_impl.dart';
import '../../features/privacy/domain/repositories/privacy_repository.dart';
import '../../features/cycles/data/datasources/cycle_remote_data_source.dart';
import '../../features/cycles/data/repositories/cycle_repository_impl.dart';
import '../../features/cycles/domain/repositories/cycle_repository.dart';
import '../../features/cycles/presentation/bloc/cycle_bloc.dart';
import '../../features/observations/data/datasources/observation_remote_data_source.dart';
import '../../features/observations/data/datasources/observation_sync_manager.dart';
import '../../features/observations/data/repositories/observation_repository_impl.dart';
import '../../features/observations/domain/repositories/observation_repository.dart';
import '../../features/observations/presentation/bloc/observation_bloc.dart';
import '../../features/observations/presentation/bloc/observation_event.dart';
import '../../features/fertility/data/datasources/fertility_remote_data_source.dart';
import '../../features/fertility/data/repositories/fertility_repository_impl.dart';
import '../../features/fertility/domain/repositories/fertility_repository.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/data/models/auth_models.dart';
import '../../features/fertility/presentation/bloc/fertility_bloc.dart';
import '../../features/notifications/data/datasources/notification_remote_data_source.dart';
import '../../features/notifications/presentation/bloc/notification_bloc.dart';

class ServiceLocator {
  static late final SecureStorageHelper storage;
  static late final ApiClient apiClient;
  static late final NetworkCubit networkCubit;

  // Auth
  static late final IAuthRemoteDataSource authRemoteDataSource;
  static late final IAuthRepository authRepository;
  static late final AuthBloc authBloc;

  // Users
  static late final IUserRemoteDataSource userRemoteDataSource;
  static late final IUserRepository userRepository;

  // Privacy
  static late final IPrivacyRemoteDataSource privacyRemoteDataSource;
  static late final IPrivacyRepository privacyRepository;

  // Cycles (Module 2)
  static late final ICycleRemoteDataSource cycleRemoteDataSource;
  static late final ICycleRepository cycleRepository;
  static late final CycleBloc cycleBloc;

  // Observations (Module 3 avec file d'attente hors-ligne)
  static late final IObservationRemoteDataSource observationRemoteDataSource;
  static late final ObservationSyncManager observationSyncManager;
  static late final IObservationRepository observationRepository;
  static late final ObservationBloc observationBloc;

  // Fertility (Module 4)
  static late final IFertilityRemoteDataSource fertilityRemoteDataSource;
  static late final IFertilityRepository fertilityRepository;
  static late final FertilityBloc fertilityBloc;

  // Notifications (Module 6 - UC-20, UC-21, UC-22)
  static late final INotificationRemoteDataSource notificationRemoteDataSource;
  static late final NotificationBloc notificationBloc;

  static Future<void> init({String? baseUrl, void Function()? onSessionExpired}) async {
    storage = SecureStorageHelper();
    networkCubit = NetworkCubit();

    // Résolution immédiate de l'état de session pour éliminer tout loader au démarrage
    AuthState initialAuthState = AuthInitialState();
    try {
      final isAuth = await storage.hasAccessToken();
      if (isAuth) {
        final userId = await storage.getUserId();
        final email = await storage.getUserEmail();
        initialAuthState = AuthenticatedState(
          AuthUserModel(
            id: userId ?? '',
            email: email ?? '',
            emailVerified: true,
          ),
        );
      } else {
        initialAuthState = UnauthenticatedState();
      }
    } catch (_) {
      initialAuthState = UnauthenticatedState();
    }

    apiClient = ApiClient(
      baseUrl: baseUrl,
      storage: storage,
      onSessionExpired: () {
        authBloc.add(LogoutRequestedEvent());
        onSessionExpired?.call();
      },
      onOnline: () => networkCubit.setOnline(),
      onOffline: () => networkCubit.setOffline(),
    );

    // Auth
    authRemoteDataSource = AuthRemoteDataSourceImpl(
      dio: apiClient.dio,
      storage: storage,
    );
    authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemoteDataSource,
      storage: storage,
    );
    authBloc = AuthBloc(
      authRepository: authRepository,
      initialState: initialAuthState,
    );

    // Users (avec cache hors-ligne)
    userRemoteDataSource = UserRemoteDataSourceImpl(
      dio: apiClient.dio,
    );
    userRepository = UserRepositoryImpl(
      remoteDataSource: userRemoteDataSource,
      storage: storage,
    );

    // Privacy & RGPD
    privacyRemoteDataSource = PrivacyRemoteDataSourceImpl(
      dio: apiClient.dio,
    );
    privacyRepository = PrivacyRepositoryImpl(
      remoteDataSource: privacyRemoteDataSource,
    );

    // Cycles (Module 2 avec cache hors-ligne)
    cycleRemoteDataSource = CycleRemoteDataSourceImpl(
      dio: apiClient.dio,
    );
    cycleRepository = CycleRepositoryImpl(
      remoteDataSource: cycleRemoteDataSource,
      storage: storage,
    );
    cycleBloc = CycleBloc(cycleRepository: cycleRepository);

    // Observations (Module 3 avec file d'attente hors-ligne & synchronisation bidirectionnelle)
    observationRemoteDataSource = ObservationRemoteDataSourceImpl(
      dio: apiClient.dio,
    );
    observationSyncManager = ObservationSyncManager(storage: storage);
    observationRepository = ObservationRepositoryImpl(
      remoteDataSource: observationRemoteDataSource,
      syncManager: observationSyncManager,
    );
    observationBloc = ObservationBloc(observationRepository: observationRepository);

    // Synchronisation automatique des observations lors du retour en ligne (Option C)
    networkCubit.stream.listen((netState) {
      if (netState.isOnline) {
        observationBloc.add(const SyncPendingObservationsEvent(isAutomatic: true));
      }
    });

    // Fertility (Module 4)
    fertilityRemoteDataSource = FertilityRemoteDataSourceImpl(
      dio: apiClient.dio,
    );
    fertilityRepository = FertilityRepositoryImpl(
      remoteDataSource: fertilityRemoteDataSource,
    );
    fertilityBloc = FertilityBloc(fertilityRepository: fertilityRepository);

    // Notifications (Module 6 - UC-20, UC-21, UC-22)
    notificationRemoteDataSource = NotificationRemoteDataSourceImpl(
      dio: apiClient.dio,
    );
    notificationBloc = NotificationBloc(
      remoteDataSource: notificationRemoteDataSource,
    );
  }
}
