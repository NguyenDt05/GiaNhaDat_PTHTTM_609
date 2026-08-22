import 'package:flutter/material.dart';

import '../models/prediction.dart';
import '../theme/app_theme.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({required this.result, super.key});

  final PredictionResult result;

  String get _displayPrice =>
      result.price.toStringAsFixed(2).replaceAll('.', ',');

  String get _displayDate {
    final date = result.createdAt.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(date.hour)}:${twoDigits(date.minute)} · '
        '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kết quả định giá')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _PriceCard(price: _displayPrice),
          const SizedBox(height: 16),
          if (result.warnings.isNotEmpty) ...[
            const _SectionTitle(
              icon: Icons.info_rounded,
              title: 'Thông tin cần lưu ý',
            ),
            const SizedBox(height: 10),
            ...result.warnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _WarningCard(warning: warning),
              ),
            ),
            const SizedBox(height: 6),
          ],
          const _SectionTitle(
            icon: Icons.analytics_rounded,
            title: 'Thông tin phân tích',
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'Thời điểm',
                    value: _displayDate,
                  ),
                  const Divider(height: 28),
                  _DetailRow(
                    icon: Icons.memory_rounded,
                    label: 'Phiên bản AI',
                    value: result.modelVersion,
                  ),
                  const Divider(height: 28),
                  _DetailRow(
                    icon: Icons.tag_rounded,
                    label: 'Mã dự đoán',
                    value: result.predictionId,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF3D899)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_rounded, color: Color(0xFF8A6412)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Giá thực tế có thể thay đổi theo thời điểm, hiện trạng và '
                    'giao dịch tại khu vực. Hãy tham khảo thêm chuyên gia trước '
                    'khi đưa ra quyết định tài chính.',
                    style: TextStyle(
                      color: Color(0xFF6C531E),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.add_home_work_rounded),
            label: const Text('Định giá bất động sản khác'),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.price});

  final String price;

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
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -44,
            child: Icon(
              Icons.location_city_rounded,
              size: 190,
              color: Colors.white.withValues(alpha: 0.055),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDEF7EF),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: AppColors.primaryDark,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'PHÂN TÍCH HOÀN TẤT',
                        style: TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 10,
                          letterSpacing: 0.7,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'GIÁ TRỊ ƯỚC TÍNH',
                  style: TextStyle(
                    color: Color(0xFFCCE2DD),
                    fontSize: 12,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'TỶ VNĐ',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 15,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.accent,
                        size: 16,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Ước tính bằng mô hình học máy',
                        style: TextStyle(color: Colors.white, fontSize: 12),
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primaryDark),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.warning});

  final PredictionWarning warning;

  @override
  Widget build(BuildContext context) {
    final referenceOnly = warning.code == 'REFERENCE_ONLY';
    final title = referenceOnly ? 'Kết quả tham khảo' : 'Ngoài vùng phổ biến';
    final icon =
        referenceOnly ? Icons.fact_check_rounded : Icons.warning_amber_rounded;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            referenceOnly ? const Color(0xFFEAF5FF) : const Color(0xFFFFF3E8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color:
              referenceOnly ? const Color(0xFFB9DBF5) : const Color(0xFFF0C99F),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: referenceOnly
                ? const Color(0xFF23658D)
                : const Color(0xFF8A551C),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  warning.message,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFE4F3EF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: AppColors.primaryDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
