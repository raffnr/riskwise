import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:riskwise/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dixsucgamxqbbbhmlrlg.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRpeHN1Y2dhbXhxYmJiaG1scmxnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTE4MDMxNTAsImV4cCI6MjA2NzM3OTE1MH0.9DIM2VxenJ9fjA8913jLwf8oL5NO5I-035zVOzURCaU',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyKeuangan',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomeScreen(), // Tampilkan HomeScreen
    );
  }
}


