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
  Future<RapportSexuelModel> logIntercourse(RapportSexuelModel intercourse);
  Future<List<RapportSexuelModel>> getIntercourseHistory({String? startDate, String? endDate});
  Future<void> deleteIntercourse(String date);
  Future<BbtAnalysisModel> getBbtAnalysis({String? startDate, String? endDate});
  Future<Map<String, dynamic>> syncBatchObservations({
    List<SaveDayObservationRequest>? mutations,
    List<Map<String, dynamic>>? deletions,
    String? since,
  });
}

class ObservationRemoteDataSourceImpl implements IObservationRemoteDataSource {
  final Dio dio;

  ObservationRemoteDataSourceImpl({required this.dio});

  @override
  Future<Map<String, dynamic>> syncBatchObservations({
    List<SaveDayObservationRequest>? mutations,
    List<Map<String, dynamic>>? deletions,
    String? since,
  }) async {
    final payload = <String, dynamic>{};
    if (mutations != null && mutations.isNotEmpty) {
      payload['mutations'] = mutations.map((m) => m.toJson()).toList();
    }
    if (deletions != null && deletions.isNotEmpty) {
      payload['deletions'] = deletions;
    }
    if (since != null) {
      payload['since'] = since;
    }

    final response = await dio.post(
      ApiConstants.observationsSyncBatch,
      data: payload,
    );
    if (response.data is Map<String, dynamic>) {
      return response.data as Map<String, dynamic>;
    }
    return {};
  }

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

  @override
  Future<RapportSexuelModel> logIntercourse(RapportSexuelModel intercourse) async {
    final response = await dio.post(
      ApiConstants.observationsIntercourse,
      data: intercourse.toJson(),
    );
    return RapportSexuelModel.fromJson(response.data as Map<String, dynamic>);
  }

  @override
  Future<List<RapportSexuelModel>> getIntercourseHistory({String? startDate, String? endDate}) async {
    final queryParams = <String, dynamic>{};
    if (startDate != null) queryParams['startDate'] = startDate;
    if (endDate != null) queryParams['endDate'] = endDate;

    final response = await dio.get(
      ApiConstants.observationsIntercourse,
      queryParameters: queryParams,
    );
    final list = response.data as List<dynamic>;
    return list.map((json) => RapportSexuelModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> deleteIntercourse(String date) async {
    await dio.delete(ApiConstants.observationsDeleteIntercourse(date));
  }

  @override
  Future<BbtAnalysisModel> getBbtAnalysis({String? startDate, String? endDate}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await dio.get(
        ApiConstants.observationsBbtAnalysis,
        queryParameters: queryParams,
      );
      if (response.data is Map<String, dynamic>) {
        return BbtAnalysisModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback local en cas d'indisponibilité temporaire du backend Render
    }

    return _computeLocalBbtAnalysis(startDate: startDate, endDate: endDate);
  }

  Future<BbtAnalysisModel> _computeLocalBbtAnalysis({String? startDate, String? endDate}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await dio.get(
        ApiConstants.observationsHistory,
        queryParameters: queryParams,
      );
      if (response.data is Map<String, dynamic>) {
        final rawTemps = (response.data['temperatures'] as List<dynamic>?) ?? [];
        final rawGlaires = (response.data['glaires'] as List<dynamic>?) ?? [];

        final temps = rawTemps
            .map((e) => TemperatureBasaleModel.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

        final mucusMap = <String, String>{};
        for (final g in rawGlaires) {
          if (g is Map<String, dynamic>) {
            final d = (g['date'] as String? ?? '').trim();
            final t = (g['typeGlaire'] ?? g['type_glaire'] ?? '') as String;
            if (d.isNotEmpty) mucusMap[d] = t;
          }
        }

        final points = <BbtPointModel>[];
        for (int i = 0; i < temps.length; i++) {
          final t = temps[i];
          points.add(BbtPointModel(
            date: t.date,
            cycleDay: i + 1,
            temperatureCelsius: t.temperatureCelsius,
            heurePrise: t.heurePrise,
            estPerturbee: t.estPerturbee,
            facteurPerturbateur: t.facteurPerturbateur,
            typeGlaire: mucusMap[t.date],
          ));
        }

        // Calcul symptothermique Roetzer
        if (points.length < 3) {
          return BbtAnalysisModel(
            status: 'insufficient_data',
            message: 'Données thermiques insuffisantes pour tracer la ligne de couverture.',
            points: points,
          );
        }

        double coverline = 0;
        int shiftIdx = -1;
        for (int i = 4; i < points.length - 2; i++) {
          final prior = points.sublist(i > 6 ? i - 6 : 0, i).where((p) => !p.estPerturbee).toList();
          if (prior.length < 3) continue;
          final maxPrior = prior.map((p) => p.temperatureCelsius).reduce((a, b) => a > b ? a : b);
          final testCov = double.parse((maxPrior + 0.05).toStringAsFixed(2));

          if (!points[i].estPerturbee &&
              points[i].temperatureCelsius >= maxPrior &&
              !points[i + 1].estPerturbee &&
              points[i + 1].temperatureCelsius >= testCov &&
              !points[i + 2].estPerturbee &&
              points[i + 2].temperatureCelsius >= maxPrior + 0.15) {
            shiftIdx = i;
            coverline = testCov;
            break;
          }
        }

        if (shiftIdx != -1) {
          final folPoints = points.sublist(0, shiftIdx);
          final lutPoints = points.sublist(shiftIdx);
          final folAvg = folPoints.map((p) => p.temperatureCelsius).reduce((a, b) => a + b) / folPoints.length;
          final lutAvg = lutPoints.map((p) => p.temperatureCelsius).reduce((a, b) => a + b) / lutPoints.length;
          final delta = double.parse((lutAvg - folAvg).toStringAsFixed(2));

          final annotated = points.asMap().entries.map((entry) {
            final idx = entry.key;
            final p = entry.value;
            return BbtPointModel(
              date: p.date,
              cycleDay: p.cycleDay,
              temperatureCelsius: p.temperatureCelsius,
              heurePrise: p.heurePrise,
              estPerturbee: p.estPerturbee,
              facteurPerturbateur: p.facteurPerturbateur,
              typeGlaire: p.typeGlaire,
              isAboveCoverline: p.temperatureCelsius >= coverline,
              phase: idx >= shiftIdx ? 'luteal' : 'follicular',
            );
          }).toList();

          return BbtAnalysisModel(
            status: 'biphasic_confirmed',
            message: 'Courbe biphasique confirmée avec décalage de +$delta °C.',
            coverlineCelsius: coverline,
            shiftDetected: true,
            shiftDate: points[shiftIdx].date,
            shiftDeltaCelsius: delta,
            follicularAvgCelsius: double.parse(folAvg.toStringAsFixed(2)),
            lutealAvgCelsius: double.parse(lutAvg.toStringAsFixed(2)),
            lutealPhaseDays: lutPoints.where((p) => p.temperatureCelsius >= coverline).length,
            points: annotated,
          );
        }

        return BbtAnalysisModel(
          status: 'follicular_phase',
          message: 'Plateau folliculaire en cours d’observation.',
          points: points,
        );
      }
    } catch (_) {}

    return const BbtAnalysisModel(
      status: 'insufficient_data',
      message: 'Enregistrez vos températures du matin pour voir votre courbe continue.',
      points: [],
    );
  }
}
