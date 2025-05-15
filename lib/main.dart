import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final keyApplicationId = '1iipsZ6YjUu1YwyFWLvGeDFzZfn3kxGenF9GdYub'; // Back4App App ID
  final keyClientKey = 'JSyTMnyupDRgUYaR5QzSj0oyFewjhON3zLP7L0Rm'; // Back4App Client Key
  final keyParseServerUrl = 'https://parseapi.back4app.com'; // Back4App Server URL

  try {
    await Parse().initialize(
      keyApplicationId,
      keyParseServerUrl,
      clientKey: keyClientKey,
      autoSendSessionId: true,
      debug: true, // Set to false in production
    );

    runApp(const MyApp());
  } catch (e) {
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Failed to initialize Parse: $e'),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CPAD Assignment: 2023TM93653',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
    );
  }
}
