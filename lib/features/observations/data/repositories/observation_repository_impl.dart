import '../../domain/repositories/observation_repository.dart';
import '../datasources/observation_remote_data_source.dart';
import '../models/observation_models.dart';

class ObservationRepositoryImpl implements IObservationRepository {
  final IObservationRemoteDataSource remoteDataSource;

  ObservationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<TypeSymptomeModel>> getSymptomCatalog() {
    return remoteDataSource.getSymptomCatalog();
  }

  @override
  Future<DayObservationsModel> getDayObservations(String date) {
    return remoteDataSource.getDayObservations(date);
  }

  @override
  Future<DayObservationsModel> saveDayObservation(SaveDayObservationRequest request) {
    return remoteDataSource.saveDayObservation(request);
  }

  @override
  Future<TemperatureBasaleModel> logTemperature(TemperatureBasaleModel temp) {
    return remoteDataSource.logTemperature(temp);
  }

  @override
  Future<GlaireCervicaleModel> logCervicalMucus(GlaireCervicaleModel mucus) {
    return remoteDataSource.logCervicalMucus(mucus);
  }

  @override
  Future<TestOvulationModel> logLhTest(TestOvulationModel test) {
    return remoteDataSource.logLhTest(test);
  }

  @override
  Future<void> deleteTemperature(String date) {
    return remoteDataSource.deleteTemperature(date);
  }

  @override
  Future<void> deleteCervicalMucus(String date) {
    return remoteDataSource.deleteCervicalMucus(date);
  }

  @override
  Future<void> deleteLhTest(String id) {
    return remoteDataSource.deleteLhTest(id);
  }

  @override
  Future<void> deleteSymptom(String id) {
    return remoteDataSource.deleteSymptom(id);
  }
}
