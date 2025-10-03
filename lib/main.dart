import 'package:flutter/material.dart';
import 'config/firebase_config.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await FirebaseConfig.initialize();
  
  runApp(const StillFeedApp());
}