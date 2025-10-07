import 'package:flutter/material.dart';
import 'config/firebase_config.dart';
import 'config/api_config.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await FirebaseConfig.initialize();
  
  // Print API configuration for debugging
  print('═══════════════════════════════════════════════════');
  ApiConfig.printBaseUrl();
  print('═══════════════════════════════════════════════════');
  
  runApp(const StillFeedApp());
}