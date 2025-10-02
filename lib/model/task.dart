import 'package:hive/hive.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? notes;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  String? dueTime;

  @HiveField(5)
  bool isCompleted;

  @HiveField(6)
  DateTime createdAt;

  @HiveField(7)
  DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.notes,
    this.dueDate,
    this.dueTime,
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Factory constructor to create a new task with generated ID
  factory Task.create({
    required String title,
    String? notes,
    DateTime? dueDate,
    String? dueTime,
  }) {
    return Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      notes: notes,
      dueDate: dueDate,
      dueTime: dueTime,
    );
  }

  // Method to update the task
  void updateTask({
    String? title,
    String? notes,
    DateTime? dueDate,
    String? dueTime,
    bool? isCompleted,
  }) {
    if (title != null) this.title = title;
    if (notes != null) this.notes = notes;
    if (dueDate != null) this.dueDate = dueDate;
    if (dueTime != null) this.dueTime = dueTime;
    if (isCompleted != null) this.isCompleted = isCompleted;
    updatedAt = DateTime.now();
  }

  // Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  // Get formatted due date string
  String get formattedDueDate {
    if (dueDate == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    
    if (taskDate == today) {
      return 'Today${dueTime != null && dueTime!.isNotEmpty ? ' at $dueTime' : ''}';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow${dueTime != null && dueTime!.isNotEmpty ? ' at $dueTime' : ''}';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday${dueTime != null && dueTime!.isNotEmpty ? ' at $dueTime' : ''}';
    } else {
      return '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}${dueTime != null && dueTime!.isNotEmpty ? ' at $dueTime' : ''}';
    }
  }

  @override
  String toString() {
    return 'Task(id: $id, title: $title, isCompleted: $isCompleted, dueDate: $dueDate)';
  }
}