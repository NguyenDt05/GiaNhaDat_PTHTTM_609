import 'package:flutter/material.dart';

import 'repositories/history_repository.dart';
import 'screens/prediction_form_screen.dart';
import 'services/api_client.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HousePriceApp());
}

class HousePriceApp extends StatelessWidget {
  const HousePriceApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = HousePriceApiClient.fromEnvironment();
    final historyRepository = HistoryRepository();
    return MaterialApp(
      title: 'Ước tính giá nhà',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: PredictionFormScreen(
        apiClient: apiClient,
        historyRepository: historyRepository,
      ),
    );
  }
}
