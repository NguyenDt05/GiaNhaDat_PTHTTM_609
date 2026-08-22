import 'package:flutter/material.dart';

import '../models/prediction.dart';
import '../repositories/history_repository.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({required this.repository, super.key});

  final HistoryRepository repository;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<PredictionResult>> _history;

  @override
  void initState() {
    super.initState();
    _history = widget.repository.load();
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(date.hour)}:${twoDigits(date.minute)} · '
        '${twoDigits(date.day)}/${twoDigits(date.month)}/${date.year}';
  }

  String _formatPrice(double price) =>
      price.toStringAsFixed(2).replaceAll('.', ',');

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_rounded),
        title: const Text('Xóa toàn bộ lịch sử?'),
        content: const Text(
          'Các kết quả đã lưu trên thiết bị sẽ bị xóa và không thể khôi phục.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Giữ lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xóa lịch sử'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.repository.clear();
    if (mounted) setState(() => _history = Future.value([]));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử định giá'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Xóa lịch sử',
              onPressed: _confirmClear,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<PredictionResult>>(
        future: _history,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _HistoryMessage(
              icon: Icons.error_outline_rounded,
              title: 'Không thể đọc lịch sử',
              message: 'Vui lòng quay lại và thử lại sau.',
            );
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return _HistoryMessage(
              icon: Icons.home_work_outlined,
              title: 'Chưa có kết quả nào',
              message: 'Các lần định giá của bạn sẽ được lưu tại đây.',
              action: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tạo dự đoán đầu tiên'),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _HistoryHeader(count: items.length);
              final item = items[index - 1];
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _HistoryCard(
                  item: item,
                  price: _formatPrice(item.price),
                  date: _formatDate(item.createdAt),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ResultScreen(result: item),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.insights_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count kết quả đã lưu',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Chạm vào một kết quả để xem chi tiết',
                  style: TextStyle(color: Color(0xFFD5E6E2), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.item,
    required this.price,
    required this.date,
    required this.onTap,
  });

  final PredictionResult item;
  final String price;
  final String date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F3EF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.home_rounded,
                  color: AppColors.primaryDark,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            price,
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 3),
                          child: Text(
                            'tỷ VNĐ',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          date,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (item.warnings.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      const Text(
                        'Kết quả tham khảo',
                        style: TextStyle(
                          color: Color(0xFF8A6412),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: const BoxDecoration(
                color: Color(0xFFE4F3EF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryDark, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.4),
            ),
            if (action != null) ...[
              const SizedBox(height: 22),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
