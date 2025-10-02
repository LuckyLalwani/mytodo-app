import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/task.dart';
import 'auth_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  // Get tasks collection for current user
  CollectionReference get _tasksCollection {
    final userId = _auth.userId;
    print('Getting tasks collection for user: $userId');
    if (userId.isEmpty) {
      print('WARNING: User ID is empty!');
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('tasks');
  }

  // Add a new task
  Future<void> addTask(Task task) async {
    try {
      print('Adding task to Firestore: ${task.title}');
      print('User ID: ${_auth.userId}');
      print('Task ID: ${task.id}');
      
      await _tasksCollection.doc(task.id).set({
        'id': task.id,
        'title': task.title,
        'notes': task.notes,
        'dueDate': task.dueDate?.millisecondsSinceEpoch,
        'dueTime': task.dueTime,
        'isCompleted': task.isCompleted,
        'createdAt': task.createdAt.millisecondsSinceEpoch,
        'updatedAt': task.updatedAt.millisecondsSinceEpoch,
      });
      
      print('Task added successfully to Firestore');
    } catch (e) {
      print('Error adding task to Firestore: $e');
      throw 'Failed to add task. Please try again.';
    }
  }

  // Update an existing task
  Future<void> updateTask(Task task) async {
    try {
      await _tasksCollection.doc(task.id).update({
        'title': task.title,
        'notes': task.notes,
        'dueDate': task.dueDate?.millisecondsSinceEpoch,
        'dueTime': task.dueTime,
        'isCompleted': task.isCompleted,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw 'Failed to update task. Please try again.';
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _tasksCollection.doc(taskId).delete();
    } catch (e) {
      throw 'Failed to delete task. Please try again.';
    }
  }

  // Get tasks stream
  Stream<List<Task>> getTasksStream() {
    print('Getting tasks stream for user: ${_auth.userId}');
    return _tasksCollection.orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) {
        print('Firestore snapshot received: ${snapshot.docs.length} documents');
        return snapshot.docs.map((doc) {
          print('Processing document: ${doc.id}');
          final data = doc.data() as Map<String, dynamic>;
          print('Document data: $data');
          return Task(
            id: data['id'] ?? '',
            title: data['title'] ?? '',
            notes: data['notes'],
            dueDate: data['dueDate'] != null
                ? DateTime.fromMillisecondsSinceEpoch(data['dueDate'])
                : null,
            dueTime: data['dueTime'],
            isCompleted: data['isCompleted'] ?? false,
            createdAt: data['createdAt'] != null
                ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
                : DateTime.now(),
            updatedAt: data['updatedAt'] != null
                ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'])
                : DateTime.now(),
          );
        }).toList();
      },
    );
  }

  // Get tasks as future (one-time fetch)
  Future<List<Task>> getTasks() async {
    try {
      final snapshot = await _tasksCollection
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Task(
          id: data['id'] ?? '',
          title: data['title'] ?? '',
          notes: data['notes'],
          dueDate: data['dueDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['dueDate'])
              : null,
          dueTime: data['dueTime'],
          isCompleted: data['isCompleted'] ?? false,
          createdAt: data['createdAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'])
              : DateTime.now(),
          updatedAt: data['updatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'])
              : DateTime.now(),
        );
      }).toList();
    } catch (e) {
      throw 'Failed to fetch tasks. Please try again.';
    }
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    try {
      await _tasksCollection.doc(taskId).update({
        'isCompleted': isCompleted,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw 'Failed to update task. Please try again.';
    }
  }

  // Delete all tasks for current user (for account deletion)
  Future<void> deleteAllTasks() async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _tasksCollection.get();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      throw 'Failed to delete tasks. Please try again.';
    }
  }

  // Sync local Hive data to Firestore (for migration)
  Future<void> syncLocalTasksToFirestore(List<Task> localTasks) async {
    try {
      final batch = _firestore.batch();
      
      for (final task in localTasks) {
        final docRef = _tasksCollection.doc(task.id);
        batch.set(docRef, {
          'id': task.id,
          'title': task.title,
          'notes': task.notes,
          'dueDate': task.dueDate?.millisecondsSinceEpoch,
          'dueTime': task.dueTime,
          'isCompleted': task.isCompleted,
          'createdAt': task.createdAt.millisecondsSinceEpoch,
          'updatedAt': task.updatedAt.millisecondsSinceEpoch,
        });
      }
      
      await batch.commit();
    } catch (e) {
      throw 'Failed to sync local tasks. Please try again.';
    }
  }
}