import 'package:example/home_page.dart';
import 'package:flutter/material.dart';
import 'package:llm_api_picker/llm_api_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the simplified memory service
  await SimpleMemoryService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomePage(),
    );
  }
}
