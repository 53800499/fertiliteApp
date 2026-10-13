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
import '../../features/observations/data/repositories/observation_repository_impl.dart';
import '../../features/observations/domain/repositories/observation_repository.dart';
import '../../features/observations/presentation/bloc/observation_bloc.dart';

class ServiceLocator {
  static late final SecureStorageHelper storage;
  static late final ApiClient apiClient;

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

  // Observations (Module 3)
  static late final IObservationRemoteDataSource observationRemoteDataSource;
  static late final IObservationRepository observationRepository;
  static late final ObservationBloc observationBloc;

  static void init({String? baseUrl, void Function()? onSessionExpired}) {
    storage = SecureStorageHelper();

    apiClient = ApiClient(
      baseUrl: baseUrl,
      storage: storage,
      onSessionExpired: () {
        authBloc.add(LogoutRequestedEvent());
        onSessionExpired?.call();
      },
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
    authBloc = AuthBloc(authRepository: authRepository);

    // Users
    userRemoteDataSource = UserRemoteDataSourceImpl(
      dio: apiClient.dio,
    );
    userRepository = UserRepositoryImpl(
      remoteDataSource: userRemoteDataSource,
    );

    // Privacy & RGPD
    privacyRemoteDataSource = PrivacyRemoteDataSourceImpl(
      dio: apiClient.dio,
    );
    privacyRepository = PrivacyRepositoryImpl(
      remoteDataSource: privacyRemoteDataSource,
    );

    // Cycles (Module 2)
    cycleRemoteDataSource = CycleRemoteDataSourceImpl(
      dio: apiClient.dio,
    );
    cycleRepository = CycleRepositoryImpl(
      remoteDataSource: cycleRemoteDataSource,
    );
    cycleBloc = CycleBloc(cycleRepository: cycleRepository);

    // Observations (Module 3)
    observationRemoteDataSource = ObservationRemoteDataSourceImpl(
      dio: apiClient.dio,
    );
    observationRepository = ObservationRepositoryImpl(
      remoteDataSource: observationRemoteDataSource,
    );
    observationBloc = ObservationBloc(observationRepository: observationRepository);
  }
}
