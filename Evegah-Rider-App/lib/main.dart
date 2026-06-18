import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
//import 'features/auth/presentation/screens/login_screen.dart';
//import 'features/dashboard/presentation/screens/main_navigation.dart';
import  'features/auth/presentation/screens/auth_wrapper.dart';

void main() {
  runApp(const EvegahApp());
}

class EvegahApp extends StatelessWidget {
  const EvegahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Evegah Rider',
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
      //home: const MainNavigation(),
    );
  }
}

/*import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 🚨 1. Import the vault package
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/screens/login_screen.dart';
//import 'features/dashboard/presentation/screens/main_navigation.dart';

// 🚨 2. Change to Future<void> and add 'async'
Future<void> main() async { 
  // 🚨 3. Ensure Flutter engine is fully awake before reading native files
  WidgetsFlutterBinding.ensureInitialized(); 
  
  // 🚨 4. Load your secret Razorpay keys from the hidden file!
  await dotenv.load(fileName: ".env"); 

  runApp(const EvegahApp());
}

class EvegahApp extends StatelessWidget {
  const EvegahApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Evegah Rider',
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
      //home: const MainNavigation(),
    );
  }
}*/
