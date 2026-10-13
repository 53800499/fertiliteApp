import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/observations/data/models/observation_models.dart';
import 'package:frontend/features/observations/domain/repositories/observation_repository.dart';
import 'package:frontend/features/observations/presentation/bloc/observation_bloc.dart';
import 'package:frontend/features/observations/presentation/bloc/observation_event.dart';
import 'package:frontend/features/observations/presentation/bloc/observation_state.dart';

class FakeObservationRepository implements IObservationRepository {
  DayObservationsModel storedDay = const DayObservationsModel(
    date: '2026-10-01',
    temperature: TemperatureBasaleModel(
      id: 't-1',
      date: '2026-10-01',
      temperatureCelsius: 36.65,
    ),
    glaire: GlaireCervicaleModel(
      id: 'g-1',
      date: '2026-10-01',
      typeGlaire: GlaireType.filantBlancOeuf,
    ),
  );

  final List<TypeSymptomeModel> catalog = const [
    TypeSymptomeModel(
      id: 'sym-1',
      code: 'tension_mammaire',
      nom: 'Tension mammaire',
      categorie: 'physique',
    ),
  ];

  @override
  Future<List<TypeSymptomeModel>> getSymptomCatalog() async => catalog;

  @override
  Future<DayObservationsModel> getDayObservations(String date) async => storedDay;

  @override
  Future<DayObservationsModel> saveDayObservation(SaveDayObservationRequest request) async {
    storedDay = DayObservationsModel(
      date: request.date,
      temperature: request.temperature,
      glaire: request.glaire,
      testsLh: request.testLh != null ? [request.testLh!] : [],
      symptomes: request.symptomes ?? [],
    );
    return storedDay;
  }

  @override
  Future<TemperatureBasaleModel> logTemperature(TemperatureBasaleModel temp) async => temp;

  @override
  Future<GlaireCervicaleModel> logCervicalMucus(GlaireCervicaleModel mucus) async => mucus;

  @override
  Future<TestOvulationModel> logLhTest(TestOvulationModel test) async => test;

  @override
  Future<void> deleteTemperature(String date) async {
    storedDay = DayObservationsModel(
      date: date,
      glaire: storedDay.glaire,
      testsLh: storedDay.testsLh,
      symptomes: storedDay.symptomes,
    );
  }

  @override
  Future<void> deleteCervicalMucus(String date) async {
    storedDay = DayObservationsModel(
      date: date,
      temperature: storedDay.temperature,
      testsLh: storedDay.testsLh,
      symptomes: storedDay.symptomes,
    );
  }

  @override
  Future<void> deleteLhTest(String id) async {}

  @override
  Future<void> deleteSymptom(String id) async {}
}

void main() {
  group('ObservationBloc Tests (Module 3)', () {
    late FakeObservationRepository fakeRepo;
    late ObservationBloc bloc;

    setUp(() {
      fakeRepo = FakeObservationRepository();
      bloc = ObservationBloc(observationRepository: fakeRepo);
    });

    tearDown(() {
      bloc.close();
    });

    test('Initial state is ObservationInitialState', () {
      expect(bloc.state, isA<ObservationInitialState>());
    });

    test('LoadDayObservationsEvent emits Loading then Loaded with catalog and day data', () async {
      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ObservationLoadingState>(),
          isA<DayObservationsLoadedState>().having(
            (s) => s.observations.temperature?.temperatureCelsius,
            'temperature',
            36.65,
          ),
        ]),
      );

      bloc.add(const LoadDayObservationsEvent('2026-10-01'));
    });

    test('SaveDayObservationEvent updates data and emits Loaded and Success', () async {
      const req = SaveDayObservationRequest(
        date: '2026-10-01',
        temperature: TemperatureBasaleModel(
          date: '2026-10-01',
          temperatureCelsius: 36.85,
        ),
      );

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<ObservationLoadingState>(),
          isA<DayObservationsLoadedState>().having(
            (s) => s.observations.temperature?.temperatureCelsius,
            'temperature updated',
            36.85,
          ),
          isA<ObservationSuccessState>(),
        ]),
      );

      bloc.add(const SaveDayObservationEvent(req));
    });
  });
}
