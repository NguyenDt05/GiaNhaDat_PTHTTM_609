import 'package:flutter_test/flutter_test.dart';
import 'package:house_price_mobile/models/prediction.dart';
import 'package:house_price_mobile/repositories/history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('stores and clears prediction history', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = HistoryRepository();
    final result = PredictionResult(
      predictionId: 'p1',
      price: 6.54,
      unit: 'billion_vnd',
      modelVersion: 'rf-v2',
      warnings: const [],
      createdAt: DateTime.utc(2026, 8, 23),
    );

    await repository.add(result);
    final history = await repository.load();

    expect(history.single.predictionId, 'p1');
    expect(history.single.price, 6.54);

    await repository.clear();
    expect(await repository.load(), isEmpty);
  });
}
