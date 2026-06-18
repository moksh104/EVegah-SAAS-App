import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evegah_maintenance/core/services/storage_service.dart';

import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load saved backend server IP before running app
  await StorageService.loadServerIp();

  runApp(const ProviderScope(child: App()));
}
