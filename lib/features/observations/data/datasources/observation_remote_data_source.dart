import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/observation_models.dart';

abstract class IObservationRemoteDataSource {
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

class ObservationRemoteDataSourceImpl implements IObservationRemoteDataSource {
  final Dio dio;

  ObservationRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<TypeSymptomeModel>> getSymptomCatalog() async {
    final response = await dio.get(ApiConstants.observationsCatalog);
    final list = response.data as List<dynamic>;
    return list.map((json) => TypeSymptomeModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<DayObservationsModel> getDayObservations(String date) async {
    final response = await dio.get(ApiConstants.observationsForDay(date));
    return DayObservationsModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<DayObservationsModel> saveDayObservation(SaveDayObservationRequest request) async {
    final response = await dio.post(
      ApiConstants.observationsDay,
      data: request.toJson(),
    );
    return DayObservationsModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<TemperatureBasaleModel> logTemperature(TemperatureBasaleModel temp) async {
    final response = await dio.post(
      ApiConstants.observationsTemperature,
      data: temp.toJson(),
    );
    return TemperatureBasaleModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<GlaireCervicaleModel> logCervicalMucus(GlaireCervicaleModel mucus) async {
    final response = await dio.post(
      ApiConstants.observationsMucus,
      data: mucus.toJson(),
    );
    return GlaireCervicaleModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<TestOvulationModel> logLhTest(TestOvulationModel test) async {
    final response = await dio.post(
      ApiConstants.observationsLh,
      data: test.toJson(),
    );
    return TestOvulationModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteTemperature(String date) async {
    await dio.delete('${ApiConstants.observationsTemperature}/$date');
  }

  @override
  Future<void> deleteCervicalMucus(String date) async {
    await dio.delete('${ApiConstants.observationsMucus}/$date');
  }

  @override
  Future<void> deleteLhTest(String id) async {
    await dio.delete('${ApiConstants.observationsLh}/$id');
  }

  @override
  Future<void> deleteSymptom(String id) async {
    await dio.delete('${ApiConstants.observationsSymptoms}/$id');
  }
}
