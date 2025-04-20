import 'package:bucketlist/screens/main_screen.dart';
import 'package:bucketlist/utils/constants.dart'; // For app colors and styles
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Main function
Future<void> main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bucket List',
      theme: AppTheme.lightTheme(),
      debugShowCheckedModeBanner: false, // Remove debug banner
      home: MainScreen(),
    );
  }
}
