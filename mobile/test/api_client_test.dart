import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:house_price_mobile/models/prediction.dart';
import 'package:house_price_mobile/services/api_client.dart';

void main() {
  test('decodes UTF-8 location options', () async {
    final mock = MockClient((request) async {
      return http.Response.bytes(
        utf8.encode('''
          {"provinces":[{"code":"P_01","label":"Hà Nội","districts":[{"code":"D_01","label":"Hà Đông"}]}]}
        '''),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final client =
        HousePriceApiClient(baseUrl: 'https://example.test', client: mock);

    final options = await client.fetchLocationOptions();

    expect(options.provinces.single.label, 'Hà Nội');
    expect(options.provinces.single.districts.single.label, 'Hà Đông');
  });

  test('retries one server error then parses prediction', () async {
    var calls = 0;
    final mock = MockClient((request) async {
      calls++;
      if (calls == 1) {
        return http.Response.bytes(
          utf8.encode('{"error":{"code":"TEMP","message":"Tạm lỗi"}}'),
          503,
        );
      }
      return http.Response.bytes(
        utf8.encode('''
          {
            "prediction_id":"p1",
            "estimated_price":{"value":6.54,"unit":"billion_vnd"},
            "model":{"version":"rf-v2"},
            "warnings":[]
          }
        '''),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final client =
        HousePriceApiClient(baseUrl: 'https://example.test', client: mock);

    final result = await client.predict(
      const PredictionInput(
        areaM2: 60,
        provinceCode: 'P_01',
        districtCode: 'D_01',
      ),
    );

    expect(calls, 2);
    expect(result.price, 6.54);
    expect(result.modelVersion, 'rf-v2');
  });

  test('maps API error to ApiException', () async {
    final mock = MockClient((request) async {
      return http.Response.bytes(
        utf8.encode(
          '{"error":{"code":"INVALID_LOCATION","message":"Địa điểm sai."}}',
        ),
        422,
      );
    });
    final client =
        HousePriceApiClient(baseUrl: 'https://example.test', client: mock);

    await expectLater(
      client.predict(
        const PredictionInput(
          areaM2: 60,
          provinceCode: 'P_01',
          districtCode: 'D_XX',
        ),
      ),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'INVALID_LOCATION')
            .having((error) => error.statusCode, 'statusCode', 422),
      ),
    );
  });
}
