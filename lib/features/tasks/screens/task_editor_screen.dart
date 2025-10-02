import 'package:flutter/material.dart';
import '../../../model/task.dart';
import '../../../services/firestore_service.dart';

class TaskEditorScreen extends StatefulWidget {
  final Task? task; // null means creating new task

  const TaskEditorScreen({super.key, this.task});

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final _formKey = GlobalKey<FormState>();

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _notesController = TextEditingController(text: widget.task?.notes ?? '');
    _selectedDate = widget.task?.dueDate;
    
    // Parse existing time if available
    if (widget.task?.dueTime != null && widget.task!.dueTime!.isNotEmpty) {
      final timeParts = widget.task!.dueTime!.split(':');
      if (timeParts.length == 2) {
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        _selectedTime = TimeOfDay(hour: hour, minute: minute);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _clearDateTime() {
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
    });
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final firestoreService = FirestoreService();
    final timeString = _selectedTime != null ? _formatTime(_selectedTime!) : null;

    try {
      print('Starting to save task...');
      
      if (_isEditing) {
        // Update existing task
        print('Updating existing task: ${widget.task!.title}');
        widget.task!.updateTask(
          title: _titleController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          dueDate: _selectedDate,
          dueTime: timeString,
        );
        await firestoreService.updateTask(widget.task!);
        print('Task updated successfully');
      } else {
        // Create new task
        print('Creating new task: ${_titleController.text.trim()}');
        final newTask = Task.create(
          title: _titleController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          dueDate: _selectedDate,
          dueTime: timeString,
        );
        print('Task object created: ${newTask.id}');
        await firestoreService.addTask(newTask);
        print('Task added to Firestore successfully');
      }

      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Task updated!' : 'Task created!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save task: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveTask,
          ),
        ],
      ),
      resizeToAvoidBottomInset: true, // This is key!
      body: Form(
        key: _formKey,
        child: SingleChildScrollView( // Wrap in SingleChildScrollView
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.task_alt),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
                maxLength: 100,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              
              // Notes field
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                maxLength: 500,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              
              // Due Date Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Due Date & Time',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_selectedDate != null || _selectedTime != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearDateTime,
                              tooltip: 'Clear date & time',
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Date picker button
                      InkWell(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 12),
                              Text(
                                _selectedDate != null
                                    ? _formatDate(_selectedDate!)
                                    : 'Select Date',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Time picker button
                      InkWell(
                        onTap: _selectTime,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time),
                              const SizedBox(width: 12),
                              Text(
                                _selectedTime != null
                                    ? _formatTime(_selectedTime!)
                                    : 'Select Time (Optional)',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Save button - moved from Spacer to bottom
              ElevatedButton.icon(
                onPressed: _saveTask,
                icon: Icon(_isEditing ? Icons.update : Icons.add),
                label: Text(_isEditing ? 'Update Task' : 'Create Task'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              
              // Add some bottom padding for keyboard
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 20 : 100),
            ],
          ),
        ),
      ),
    );
  }
}