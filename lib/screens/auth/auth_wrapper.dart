import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../model/task.dart';
import 'login_screen.dart';
import '../tasks/task_list_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData) {
          // User is signed in
          return const TaskSyncWrapper();
        } else {
          // User is not signed in
          return const LoginScreen();
        }
      },
    );
  }
}

class TaskSyncWrapper extends StatefulWidget {
  const TaskSyncWrapper({super.key});

  @override
  State<TaskSyncWrapper> createState() => _TaskSyncWrapperState();
}

class _TaskSyncWrapperState extends State<TaskSyncWrapper> {
  bool _syncComplete = false;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _initializeAndSync();
  }

  Future<void> _initializeAndSync() async {
    try {
      // Ensure tasks box is open
      if (!Hive.isBoxOpen('tasks')) {
        await Hive.openBox<Task>('tasks');
      }

      await _syncLocalTasksToFirestore();
    } catch (e) {
      print('Error during initialization: $e');
      if (mounted) {
        setState(() => _syncComplete = true);
      }
    }
  }

  Future<void> _syncLocalTasksToFirestore() async {
    try {
      final taskBox = Hive.box<Task>('tasks');
      final localTasks = taskBox.values.toList();
      
      if (localTasks.isNotEmpty) {
        // Show sync dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Syncing your tasks...'),
                ],
              ),
            ),
          );
        }

        // Sync local tasks to Firestore
        await _firestoreService.syncLocalTasksToFirestore(localTasks);
        
        // Clear local tasks after successful sync
        await taskBox.clear();
        
        if (mounted) {
          Navigator.of(context).pop(); // Close sync dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tasks synced successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Sync error: $e');
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.of(context).pop(); // Close sync dialog if open
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _syncComplete = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_syncComplete) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Setting up your account...'),
            ],
          ),
        ),
      );
    }

    return const TaskListScreen();
  }
}