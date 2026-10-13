import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/observations/data/models/observation_models.dart';

void main() {
  group('Observation Models (Module 3 - M3)', () {
    test('TemperatureBasaleModel serialization and formatting', () {
      final json = {
        'id': 't-1',
        'date': '2026-10-01',
        'temperatureCelsius': 36.65,
        'heurePrise': '07:15',
        'estPerturbee': true,
        'facteurPerturbateur': 'alcool',
        'notes': 'Soirée entre amis',
      };

      final model = TemperatureBasaleModel.fromJson(json);
      expect(model.id, 't-1');
      expect(model.date, '2026-10-01');
      expect(model.temperatureCelsius, 36.65);
      expect(model.formattedTemp, '36.65 °C');
      expect(model.estPerturbee, isTrue);
      expect(model.facteurPerturbateur, 'alcool');

      final serialized = model.toJson();
      expect(serialized['temperatureCelsius'], 36.65);
      expect(serialized['estPerturbee'], isTrue);
    });

    test('GlaireCervicaleModel serialization and fertility detection', () {
      final jsonFertile = {
        'id': 'g-1',
        'date': '2026-10-01',
        'typeGlaire': GlaireType.filantBlancOeuf,
      };

      final modelFertile = GlaireCervicaleModel.fromJson(jsonFertile);
      expect(modelFertile.isFertile, isTrue);
      expect(modelFertile.label, contains("Blanc d'œuf"));

      final jsonSec = {
        'id': 'g-2',
        'date': '2026-10-02',
        'typeGlaire': GlaireType.sec,
      };
      final modelSec = GlaireCervicaleModel.fromJson(jsonSec);
      expect(modelSec.isFertile, isFalse);
    });

    test('TestOvulationModel peak detection', () {
      final jsonPeak = {
        'id': 'lh-1',
        'date': '2026-10-01',
        'resultat': LhResult.pic,
        'valeurMUiMl': 65.0,
      };
      final modelPeak = TestOvulationModel.fromJson(jsonPeak);
      expect(modelPeak.isPeak, isTrue);
      expect(modelPeak.label, 'Pic de LH');

      final jsonNeg = {
        'id': 'lh-2',
        'date': '2026-10-02',
        'resultat': LhResult.negatif,
      };
      final modelNeg = TestOvulationModel.fromJson(jsonNeg);
      expect(modelNeg.isPeak, isFalse);
    });

    test('DayObservationsModel hasObservations', () {
      const emptyDay = DayObservationsModel(date: '2026-10-01');
      expect(emptyDay.hasObservations, isFalse);

      const dayWithTemp = DayObservationsModel(
        date: '2026-10-01',
        temperature: TemperatureBasaleModel(
          date: '2026-10-01',
          temperatureCelsius: 36.6,
        ),
      );
      expect(dayWithTemp.hasObservations, isTrue);
    });

    test('SaveDayObservationRequest serialization', () {
      const req = SaveDayObservationRequest(
        date: '2026-10-01',
        temperature: TemperatureBasaleModel(
          date: '2026-10-01',
          temperatureCelsius: 36.7,
        ),
        glaire: GlaireCervicaleModel(
          date: '2026-10-01',
          typeGlaire: GlaireType.filantBlancOeuf,
        ),
      );

      final json = req.toJson();
      expect(json['date'], '2026-10-01');
      expect(json['temperature']['temperatureCelsius'], 36.7);
      expect(json['glaire']['typeGlaire'], GlaireType.filantBlancOeuf);
    });
  });
}
