import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/cycles/data/models/cycle_models.dart';

void main() {
  group('Cycle Models (Module 2 - M2)', () {
    test('JourReglesModel serialization & deserialization', () {
      final json = {
        'id': 'jour-1',
        'cycleId': 'cycle-1',
        'date': '2026-09-24',
        'intensiteFlux': 'abondant',
        'douleurNiveau': 4,
        'notes': 'Crampes modérées',
      };

      final model = JourReglesModel.fromJson(json);
      expect(model.id, 'jour-1');
      expect(model.cycleId, 'cycle-1');
      expect(model.date, '2026-09-24');
      expect(model.intensiteFlux, 'abondant');
      expect(model.douleurNiveau, 4);
      expect(model.notes, 'Crampes modérées');

      final serialized = model.toJson();
      expect(serialized['id'], 'jour-1');
      expect(serialized['intensiteFlux'], 'abondant');
    });

    test('CycleModel currentCycleDay computation', () {
      final today = DateTime.now();
      final fiveDaysAgo = today.subtract(const Duration(days: 4));
      final dateStr =
          "${fiveDaysAgo.year.toString().padLeft(4, '0')}-${fiveDaysAgo.month.toString().padLeft(2, '0')}-${fiveDaysAgo.day.toString().padLeft(2, '0')}";

      final cycle = CycleModel(
        id: 'cycle-active',
        dateDebut: dateStr,
        statut: 'en_cours',
      );

      expect(cycle.isEnCours, isTrue);
      expect(cycle.currentCycleDay, 5);
    });

    test('CycleStatsModel regularity computation label', () {
      const statsRegular = CycleStatsModel(
        totalCycles: 6,
        completedCycles: 6,
        averageDuration: 28.2,
        minDuration: 27,
        maxDuration: 29,
        standardDeviation: 0.8,
        regularity: 'tres_regulier',
        averagePeriodDuration: 4.8,
        history: [],
      );

      expect(statsRegular.regularityLabel, contains('Très régulier'));

      const statsIrregular = CycleStatsModel(
        totalCycles: 4,
        completedCycles: 4,
        averageDuration: 32.0,
        minDuration: 24,
        maxDuration: 39,
        standardDeviation: 5.2,
        regularity: 'irregulier',
        averagePeriodDuration: 5.5,
        history: [],
      );

      expect(statsIrregular.regularityLabel, contains('Irrégulier'));
    });
  });
}
