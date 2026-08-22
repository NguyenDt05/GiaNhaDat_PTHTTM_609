class PredictionInput {
  const PredictionInput({
    required this.areaM2,
    required this.provinceCode,
    required this.districtCode,
    this.frontageM,
    this.accessRoadWidthM,
    this.floors,
    this.bedrooms,
    this.bathrooms,
    this.houseDirection,
    this.balconyDirection,
    this.legalStatus,
    this.furnitureState,
  });

  final double areaM2;
  final double? frontageM;
  final double? accessRoadWidthM;
  final int? floors;
  final int? bedrooms;
  final int? bathrooms;
  final String? houseDirection;
  final String? balconyDirection;
  final String? legalStatus;
  final String? furnitureState;
  final String provinceCode;
  final String districtCode;

  Map<String, dynamic> toJson() => {
        'area_m2': areaM2,
        'frontage_m': frontageM,
        'access_road_width_m': accessRoadWidthM,
        'floors': floors,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'house_direction': houseDirection,
        'balcony_direction': balconyDirection,
        'legal_status': legalStatus,
        'furniture_state': furnitureState,
        'province_code': provinceCode,
        'district_code': districtCode,
      };
}

class PredictionWarning {
  const PredictionWarning({required this.code, required this.message});

  final String code;
  final String message;

  factory PredictionWarning.fromJson(Map<String, dynamic> json) {
    return PredictionWarning(
      code: json['code'] as String,
      message: json['message'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'code': code, 'message': message};
}

class PredictionResult {
  const PredictionResult({
    required this.predictionId,
    required this.price,
    required this.unit,
    required this.modelVersion,
    required this.warnings,
    required this.createdAt,
  });

  final String predictionId;
  final double price;
  final String unit;
  final String modelVersion;
  final List<PredictionWarning> warnings;
  final DateTime createdAt;

  factory PredictionResult.fromApiJson(Map<String, dynamic> json) {
    final estimatedPrice = json['estimated_price'] as Map<String, dynamic>;
    final model = json['model'] as Map<String, dynamic>;
    return PredictionResult(
      predictionId: json['prediction_id'] as String,
      price: (estimatedPrice['value'] as num).toDouble(),
      unit: estimatedPrice['unit'] as String,
      modelVersion: model['version'] as String,
      warnings: (json['warnings'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(PredictionWarning.fromJson)
          .toList(growable: false),
      createdAt: DateTime.now(),
    );
  }

  factory PredictionResult.fromStorageJson(Map<String, dynamic> json) {
    return PredictionResult(
      predictionId: json['prediction_id'] as String,
      price: (json['price'] as num).toDouble(),
      unit: json['unit'] as String,
      modelVersion: json['model_version'] as String,
      warnings: (json['warnings'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(PredictionWarning.fromJson)
          .toList(growable: false),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toStorageJson() => {
        'prediction_id': predictionId,
        'price': price,
        'unit': unit,
        'model_version': modelVersion,
        'warnings': warnings.map((item) => item.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
      };
}
