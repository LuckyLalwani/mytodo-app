import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth/auth_wrapper.dart';
import 'model/task.dart';

// Global theme controller
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Task adapter if not already registered
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TaskAdapter());
  }

  // Open both settings and tasks boxes
  await Hive.openBox('settings');
  await Hive.openBox<Task>('tasks'); // Make sure tasks box is opened

  // Load saved theme
  final settingsBox = Hive.box('settings');
  dynamic savedTheme = settingsBox.get('themeMode', defaultValue: 'system');
  if (savedTheme is bool) {
    savedTheme = savedTheme ? 'dark' : 'light';
    await settingsBox.put('themeMode', savedTheme);
  } else if (savedTheme is! String) {
    savedTheme = 'system';
    await settingsBox.put('themeMode', savedTheme);
  }

  themeNotifier.value = savedTheme == 'dark'
      ? ThemeMode.dark
      : savedTheme == 'light'
          ? ThemeMode.light
          : ThemeMode.system;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'MyTodo',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData.light(useMaterial3: true).copyWith(
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          darkTheme: ThemeData.dark(useMaterial3: true),
          home: const AuthWrapper(),
        );
      },
    );
  }
}