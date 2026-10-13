import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/fertility/data/models/fertility_models.dart';

void main() {
  group('Fertility Models (Module 4 - M4)', () {
    test('PredictionModel.fromJson parses fields correctly', () {
      final json = {
        'predictionId': 'pred-123',
        'generationDate': '2026-10-13T10:00:00.000Z',
        'estimatedOvulationDate': '2026-10-15',
        'uncertaintyMarginDays': 1,
        'fertileWindow': {
          'startDate': '2026-10-09',
          'endDate': '2026-10-17',
        },
        'fertilityCategory': 'elevee',
        'fertilityScoreValue': 85.5,
        'confidenceLevel': 'eleve',
        'method': 'calendrier_statistique',
        'algorithm': 'calendar_v1',
        'modelVersion': 'v1.0-calendrier',
        'factors': [
          {
            'id': 'fact-1',
            'type': 'historique_cycles',
            'description': 'Vos cycles sont réguliers',
            'weight': 0.45,
            'direction': 'renforce',
            'displayOrder': 1,
          },
        ],
      };

      final model = PredictionModel.fromJson(json);

      expect(model.predictionId, 'pred-123');
      expect(model.estimatedOvulationDate, '2026-10-15');
      expect(model.uncertaintyMarginDays, 1);
      expect(model.fertileWindow.startDate, '2026-10-09');
      expect(model.fertileWindow.endDate, '2026-10-17');
      expect(model.fertilityCategory, 'elevee');
      expect(model.fertilityScoreValue, 85.5);
      expect(model.confidenceLevel, 'eleve');
      expect(model.factors.length, 1);
      expect(model.factors.first.direction, 'renforce');
    });

    test('CalendarMonthModel.fromJson parses day summaries', () {
      final json = {
        'year': 2026,
        'month': 10,
        'estimatedOvulationDate': '2026-10-15',
        'days': [
          {
            'date': '2026-10-15',
            'isPeriodDay': false,
            'isFertileDay': true,
            'isOvulationDay': true,
            'fertilityCategory': 'elevee',
            'fertilityScore': 80.0,
            'hasObservations': false,
          },
        ],
      };

      final monthModel = CalendarMonthModel.fromJson(json);

      expect(monthModel.year, 2026);
      expect(monthModel.month, 10);
      expect(monthModel.days.length, 1);
      expect(monthModel.days.first.isOvulationDay, true);
    });
  });
}
