import 'package:flutter_test/flutter_test.dart';
import 'package:house_price_mobile/models/prediction.dart';

void main() {
  test('parses prediction response and preserves model version', () {
    final result = PredictionResult.fromApiJson({
      'prediction_id': 'prediction-1',
      'estimated_price': {'value': 6.67, 'unit': 'billion_vnd'},
      'model': {'version': 'rf-v2'},
      'warnings': [
        {'code': 'REFERENCE_ONLY', 'message': 'Kết quả tham khảo.'},
      ],
    });

    expect(result.price, 6.67);
    expect(result.modelVersion, 'rf-v2');
    expect(result.warnings.single.code, 'REFERENCE_ONLY');
  });

  test('serializes nullable prediction inputs', () {
    const input = PredictionInput(
      areaM2: 60,
      provinceCode: 'P_01',
      districtCode: 'D_001',
    );

    expect(input.toJson()['area_m2'], 60);
    expect(input.toJson()['frontage_m'], isNull);
  });
}
