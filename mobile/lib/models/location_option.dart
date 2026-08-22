class DistrictOption {
  const DistrictOption({required this.code, required this.label});

  final String code;
  final String label;

  factory DistrictOption.fromJson(Map<String, dynamic> json) {
    return DistrictOption(
      code: json['code'] as String,
      label: json['label'] as String,
    );
  }
}

class ProvinceOption {
  const ProvinceOption({
    required this.code,
    required this.label,
    required this.districts,
  });

  final String code;
  final String label;
  final List<DistrictOption> districts;

  factory ProvinceOption.fromJson(Map<String, dynamic> json) {
    final districts = (json['districts'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(DistrictOption.fromJson)
        .toList(growable: false);
    return ProvinceOption(
      code: json['code'] as String,
      label: json['label'] as String,
      districts: districts,
    );
  }
}

class LocationOptions {
  const LocationOptions({required this.provinces});

  final List<ProvinceOption> provinces;

  factory LocationOptions.fromJson(Map<String, dynamic> json) {
    final provinces = (json['provinces'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ProvinceOption.fromJson)
        .toList(growable: false);
    return LocationOptions(provinces: provinces);
  }
}
