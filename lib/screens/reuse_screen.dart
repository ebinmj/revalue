import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'reuse_marketplace_screen.dart';

class ReuseScreen extends StatelessWidget {
  const ReuseScreen({this.apiService, super.key});

  final ApiService? apiService;

  @override
  Widget build(BuildContext context) =>
      ReuseMarketplaceScreen(apiService: apiService);
}
