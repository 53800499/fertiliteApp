import '../../data/models/observation_models.dart';

abstract class IObservationRepository {
  Future<List<TypeSymptomeModel>> getSymptomCatalog();
  Future<DayObservationsModel> getDayObservations(String date);
  Future<DayObservationsModel> saveDayObservation(SaveDayObservationRequest request);
  Future<TemperatureBasaleModel> logTemperature(TemperatureBasaleModel temp);
  Future<GlaireCervicaleModel> logCervicalMucus(GlaireCervicaleModel mucus);
  Future<TestOvulationModel> logLhTest(TestOvulationModel test);
  Future<void> deleteTemperature(String date);
  Future<void> deleteCervicalMucus(String date);
  Future<void> deleteLhTest(String id);
  Future<void> deleteSymptom(String id);
}
