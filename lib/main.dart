import 'package:cache_money_attendance/home_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

/// This sets up that it's a MaterialApp and initializes the theming. It is the root of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '8096 Attendance',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff16543c), brightness: Brightness.light),
        useMaterial3: true,
      ),
      // hell yeah we got dark mode
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff16543c), brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const UIStructure(title: 'Home'),
    );
  }
}

/// This widget sets up the structure of the UI, including the app bar (using the theming created above) and initializes the HomePage widget.
class UIStructure extends StatefulWidget {
  const UIStructure({super.key, required this.title});

  final String title;

  @override
  State<UIStructure> createState() => _UIStructureState();
}

class _UIStructureState extends State<UIStructure> {
  DatabaseReference ref = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: const HomePage(),
    );
  }

  // This code isn't currently used but could be useful sometime in the future for getting data from the database.
  Future<DataSnapshot> getDbEvent(String child) async {
    return await ref.child('').get();
  }
}
