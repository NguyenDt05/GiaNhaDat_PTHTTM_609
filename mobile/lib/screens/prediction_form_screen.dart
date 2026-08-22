import 'package:flutter/material.dart';

import '../models/location_option.dart';
import '../models/prediction.dart';
import '../repositories/history_repository.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'result_screen.dart';

class PredictionFormScreen extends StatefulWidget {
  const PredictionFormScreen({
    required this.apiClient,
    required this.historyRepository,
    super.key,
  });

  final HousePriceApiClient apiClient;
  final HistoryRepository historyRepository;

  @override
  State<PredictionFormScreen> createState() => _PredictionFormScreenState();
}

class _PredictionFormScreenState extends State<PredictionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _area = TextEditingController();
  final _frontage = TextEditingController();
  final _accessRoad = TextEditingController();
  final _floors = TextEditingController();
  final _bedrooms = TextEditingController();
  final _bathrooms = TextEditingController();

  List<ProvinceOption> _provinces = [];
  ProvinceOption? _province;
  DistrictOption? _district;
  String? _houseDirection;
  String? _balconyDirection;
  String? _legalStatus;
  String? _furnitureState;
  bool _loadingOptions = true;
  bool _submitting = false;
  String? _loadError;

  static const _directions = {
    'NORTH': 'Bắc',
    'NORTHEAST': 'Đông Bắc',
    'EAST': 'Đông',
    'SOUTHEAST': 'Đông Nam',
    'SOUTH': 'Nam',
    'SOUTHWEST': 'Tây Nam',
    'WEST': 'Tây',
    'NORTHWEST': 'Tây Bắc',
  };

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _area.dispose();
    _frontage.dispose();
    _accessRoad.dispose();
    _floors.dispose();
    _bedrooms.dispose();
    _bathrooms.dispose();
    widget.apiClient.close();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loadingOptions = true;
      _loadError = null;
    });
    try {
      final options = await widget.apiClient.fetchLocationOptions();
      if (!mounted) return;
      setState(() {
        _provinces = options.provinces;
        _province = _provinces.isEmpty ? null : _provinces.first;
        _district = _province == null || _province!.districts.isEmpty
            ? null
            : _province!.districts.first;
        _loadingOptions = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.message;
        _loadingOptions = false;
      });
    }
  }

  double? _optionalDouble(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : double.tryParse(value.replaceAll(',', '.'));
  }

  int? _optionalInt(TextEditingController controller) {
    final value = controller.text.trim();
    return value.isEmpty ? null : int.tryParse(value);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() ||
        _province == null ||
        _district == null) {
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await widget.apiClient.predict(
        PredictionInput(
          areaM2: double.parse(_area.text.trim().replaceAll(',', '.')),
          frontageM: _optionalDouble(_frontage),
          accessRoadWidthM: _optionalDouble(_accessRoad),
          floors: _optionalInt(_floors),
          bedrooms: _optionalInt(_bedrooms),
          bathrooms: _optionalInt(_bathrooms),
          houseDirection: _houseDirection,
          balconyDirection: _balconyDirection,
          legalStatus: _legalStatus,
          furnitureState: _furnitureState,
          provinceCode: _province!.code,
          districtCode: _district!.code,
        ),
      );
      await widget.historyRepository.add(result);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ResultScreen(result: result)),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(error.message)),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _requiredPositiveNumber(String? value) {
    final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (number == null || number <= 0) return 'Nhập số lớn hơn 0';
    return null;
  }

  String? _optionalPositiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = double.tryParse(value.trim().replaceAll(',', '.'));
    if (number == null || number <= 0) return 'Phải lớn hơn 0';
    return null;
  }

  String? _optionalPositiveInteger(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final number = int.tryParse(value.trim());
    if (number == null || number <= 0) return 'Nhập số nguyên dương';
    return null;
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 20,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('HouseValue AI'),
          Text(
            'Định giá bất động sản',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton.filledTonal(
            tooltip: 'Lịch sử dự đoán',
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    HistoryScreen(repository: widget.historyRepository),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      appBar: _buildAppBar(),
      body: _loadingOptions
          ? const _LoadingView()
          : _loadError != null
              ? _ErrorView(message: _loadError!, onRetry: _loadOptions)
              : _buildForm(),
      bottomNavigationBar: _loadingOptions || _loadError != null || keyboardOpen
          ? null
          : _SubmitBar(submitting: _submitting, onSubmit: _submit),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const _HeroBanner(),
          const SizedBox(height: 16),
          _FormSection(
            icon: Icons.location_on_rounded,
            title: 'Vị trí bất động sản',
            subtitle: 'Khu vực là yếu tố quan trọng nhất trong định giá',
            child: Column(
              children: [
                DropdownButtonFormField<ProvinceOption>(
                  initialValue: _province,
                  isExpanded: true,
                  menuMaxHeight: 360,
                  decoration: const InputDecoration(
                    labelText: 'Tỉnh / thành phố',
                    prefixIcon: Icon(Icons.location_city_rounded),
                  ),
                  items: _provinces
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() {
                    _province = value;
                    _district = value == null || value.districts.isEmpty
                        ? null
                        : value.districts.first;
                  }),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DistrictOption>(
                  key: ValueKey(_province?.code),
                  initialValue: _district,
                  isExpanded: true,
                  menuMaxHeight: 360,
                  decoration: const InputDecoration(
                    labelText: 'Quận / huyện',
                    prefixIcon: Icon(Icons.map_rounded),
                  ),
                  items: (_province?.districts ?? [])
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(
                            item.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _district = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FormSection(
            icon: Icons.straighten_rounded,
            title: 'Diện tích & tiếp cận',
            subtitle: 'Điền các thông số đo thực tế nếu có',
            child: _FieldGrid(
              children: [
                _numberField(
                  _area,
                  'Diện tích *',
                  _requiredPositiveNumber,
                  icon: Icons.square_foot_rounded,
                  suffix: 'm²',
                ),
                _numberField(
                  _frontage,
                  'Mặt tiền',
                  _optionalPositiveNumber,
                  icon: Icons.width_full_rounded,
                  suffix: 'm',
                ),
                _numberField(
                  _accessRoad,
                  'Đường vào',
                  _optionalPositiveNumber,
                  icon: Icons.add_road_rounded,
                  suffix: 'm',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FormSection(
            icon: Icons.apartment_rounded,
            title: 'Quy mô sử dụng',
            subtitle: 'Các trường không rõ có thể để trống',
            child: _FieldGrid(
              children: [
                _numberField(
                  _floors,
                  'Số tầng',
                  _optionalPositiveInteger,
                  icon: Icons.layers_rounded,
                  integer: true,
                ),
                _numberField(
                  _bedrooms,
                  'Phòng ngủ',
                  _optionalPositiveInteger,
                  icon: Icons.bed_rounded,
                  integer: true,
                ),
                _numberField(
                  _bathrooms,
                  'Phòng tắm',
                  _optionalPositiveInteger,
                  icon: Icons.bathtub_rounded,
                  integer: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FormSection(
            icon: Icons.tune_rounded,
            title: 'Đặc điểm bổ sung',
            subtitle: 'Thông tin chi tiết giúp kết quả sát thực tế hơn',
            child: Column(
              children: [
                _stringDropdown(
                  label: 'Hướng nhà',
                  icon: Icons.explore_rounded,
                  value: _houseDirection,
                  values: _directions,
                  onChanged: (value) => setState(() => _houseDirection = value),
                ),
                const SizedBox(height: 12),
                _stringDropdown(
                  label: 'Hướng ban công',
                  icon: Icons.balcony_rounded,
                  value: _balconyDirection,
                  values: _directions,
                  onChanged: (value) =>
                      setState(() => _balconyDirection = value),
                ),
                const SizedBox(height: 12),
                _stringDropdown(
                  label: 'Tình trạng pháp lý',
                  icon: Icons.verified_user_rounded,
                  value: _legalStatus,
                  values: const {
                    'CERTIFICATE': 'Có giấy chứng nhận',
                    'SALE_CONTRACT': 'Hợp đồng mua bán',
                  },
                  onChanged: (value) => setState(() => _legalStatus = value),
                ),
                const SizedBox(height: 12),
                _stringDropdown(
                  label: 'Tình trạng nội thất',
                  icon: Icons.chair_rounded,
                  value: _furnitureState,
                  values: const {'FULL': 'Đầy đủ', 'BASIC': 'Cơ bản'},
                  onChanged: (value) => setState(() => _furnitureState = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded,
                  size: 15, color: AppColors.muted),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Dữ liệu chỉ được dùng để tạo kết quả dự đoán',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    String? Function(String?) validator, {
    required IconData icon,
    bool integer = false,
    String? suffix,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixText: suffix,
      ),
      keyboardType: TextInputType.numberWithOptions(decimal: !integer),
      textInputAction: TextInputAction.next,
      validator: validator,
    );
  }

  Widget _stringDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required Map<String, String> values,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      items: [
        const DropdownMenuItem<String>(value: null, child: Text('Không rõ')),
        ...values.entries.map(
          (entry) => DropdownMenuItem(
            value: entry.key,
            child: Text(entry.value, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.primaryDark, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            top: -44,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            right: 42,
            bottom: -58,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.real_estate_agent_rounded,
                    color: Colors.white,
                    size: 29,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AiBadge(),
                      SizedBox(height: 10),
                      Text(
                        'Ước tính giá trị ngôi nhà của bạn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Nhập thông tin bên dưới để nhận kết quả trong vài giây.',
                        style: TextStyle(
                          color: Color(0xFFDCEBE7),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  const _AiBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 13, color: AppColors.navy),
          SizedBox(width: 5),
          Text(
            'AI POWERED',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 10,
              letterSpacing: 0.7,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F3EF),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: AppColors.primaryDark, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _FieldGrid extends StatelessWidget {
  const _FieldGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 270 ? 2 : 1;
        const spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.submitting, required this.onSubmit});

  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE4ECE9))),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: FilledButton.icon(
            onPressed: submitting ? null : onSubmit,
            icon: submitting
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : const Icon(Icons.auto_awesome_rounded),
            label: Text(
              submitting ? 'AI đang phân tích...' : 'Ước tính giá ngay',
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: 42,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(height: 18),
          Text(
            'Đang tải dữ liệu khu vực...',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEDEA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: Color(0xFFBA1A1A),
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Không thể kết nối máy chủ',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Kết nối lại'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
