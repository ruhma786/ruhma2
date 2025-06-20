import 'package:flutter/material.dart';
import 'task.dart';
import 'notification_util.dart'; // Ensure this file contains a function for notifications
import 'pdf.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Import for Timer
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'database.dart';

class TaskListScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;

  TaskListScreen({required this.onThemeToggle});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _startTimer();
  }

  void _loadTasks() async {
    final tasks = await TaskDatabase.instance.readAllTasks();
    setState(() {
      _tasks = tasks;
    });
  }

  void _addTask(Task task) async {
    final newTask = await TaskDatabase.instance.createTask(task);
    setState(() {
      _tasks.add(newTask);
    });
    _startTimer();
  }

  // Function to check task status and send notifications
  void _startTimer() {
    _timer?.cancel(); // Cancel any existing timer to avoid duplication

    _timer = Timer.periodic(Duration(minutes: 1), (_) {
      final now = DateTime.now();

      // Check each task for time remaining and notify
      for (var task in _tasks) {
        DateTime taskDueDate = DateTime.parse(task.dueDate);
        Duration remainingTime = taskDueDate.difference(now);

        if (!task.isCompleted && remainingTime.isNegative) {
          // If the task is overdue, notify
          NotificationUtil.showNotification(task.title, "Task overdue!");
        } else if (!task.isCompleted && remainingTime.inMinutes <= 30 && !remainingTime.isNegative) {
          // Notify if the task is due within the next 30 minutes
          NotificationUtil.showNotification(task.title, "Task due soon!");
        } else if (task.isRepeated && task.repeatFrequency == 'daily' && taskDueDate.isBefore(now)) {
          // Update the due date for daily repeated tasks to the next day
          setState(() {
            task.dueDate = taskDueDate.add(Duration(days: 1)).toIso8601String();
          });
        }
      }
      _loadTasks(); // Reload tasks to reflect updated repeat tasks
    });
  }


  // Filter tasks for Today, Upcoming, Repeat, and Completed
  List<Task> get _todayTasks {
    final today = DateTime.now();
    return _tasks.where((task) {
      final dueDate = DateTime.parse(task.dueDate);
      return dueDate.year == today.year &&
          dueDate.month == today.month &&
          dueDate.day == today.day;
    }).toList();
  }

  List<Task> get _upcomingTasks {
    final today = DateTime.now();
    return _tasks.where((task) {
      final dueDate = DateTime.parse(task.dueDate);
      return dueDate.isAfter(today) && !task.isCompleted;
    }).toList();
  }

  List<Task> get _repeatTasks {
    final today = DateTime.now();
    return _tasks.where((task) {
      final dueDate = DateTime.parse(task.dueDate);
      return task.isRepeated &&
          dueDate.isBefore(today) &&
          !task.isCompleted;
    }).toList();
  }

  List<Task> get _completedTasks {
    return _tasks.where((task) => task.isCompleted).toList();
  }

  void _editTask(int index, Task updatedTask) {
    setState(() {
      _tasks[index] = updatedTask;
    });
    _loadTasks(); // Recheck task status after edit
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    _loadTasks(); // Recheck task status after deletion
  }

  void _markAsCompleted(int index) async {
    setState(() {
      _tasks[index].toggleCompletion();

      if (_tasks[index].isCompleted && _tasks[index].isRepeated) {
        DateTime newDueDate = DateTime.parse(_tasks[index].dueDate);

        if (_tasks[index].repeatFrequency == 'daily') {
          newDueDate = newDueDate.add(Duration(days: 1));
        } else if (_tasks[index].repeatFrequency == 'weekly' &&
            _tasks[index].repeatDays != null &&
            _tasks[index].repeatDays!.isNotEmpty) {
          newDueDate =
              _findNextRepeatDate(newDueDate, _tasks[index].repeatDays!);
        }

        _tasks[index] = Task(
          title: _tasks[index].title,
          description: _tasks[index].description,
          dueDate: newDueDate.toIso8601String(),
          isRepeated: true,
          isCompleted: false,
          completionPercentage: 0.0,
          repeatFrequency: _tasks[index].repeatFrequency,
          repeatDays: _tasks[index].repeatDays,
        );
      }
    });
  }

  DateTime _findNextRepeatDate(DateTime currentDate, List<int> repeatDays) {
    DateTime nextDate = currentDate.add(Duration(days: 1));
    while (!repeatDays.contains(nextDate.weekday)) {
      nextDate = nextDate.add(Duration(days: 1));
    }
    return nextDate;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task List'),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: widget.onThemeToggle,
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: () async {
              await exportTasksToPDF(context, _tasks);
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          if (_todayTasks.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Today',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ..._todayTasks.map((task) => _buildTaskItem(task)),

          if (_upcomingTasks.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Upcoming',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ..._upcomingTasks.map((task) => _buildTaskItem(task)),

          if (_repeatTasks.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Repeat Tasks',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ..._repeatTasks.map((task) => _buildTaskItem(task)),

          if (_completedTasks.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Completed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ..._completedTasks.map((task) => _buildTaskItem(task)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTask = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTaskScreen(),
            ),
          );
          if (newTask != null && newTask is Task) {
            _addTask(newTask);
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    final index = _tasks.indexOf(task);
    final dueDate = DateTime.parse(task.dueDate);
    final timeRemaining = dueDate.difference(DateTime.now());

    String timeRemainingText = timeRemaining.isNegative
        ? "Overdue"
        : "${timeRemaining.inHours} hours ${timeRemaining.inMinutes %
        60} minutes remaining";

    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.edit),
            color: Colors.cyan,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditTaskScreen(
                        task: task,
                        onUpdate: (updatedTask) {
                          _editTask(index, updatedTask);
                        },
                        onDelete: () {
                          _deleteTask(index);
                        },
                      ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            color: Colors.pink,
            onPressed: () {
              _deleteTask(index);
            },
          ),
        ],
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.description),
          if (task.isRepeated && task.repeatFrequency != 'none') ...[
            Text('Repeat: ${task.repeatFrequency!.capitalize()}'),
            if (task.repeatFrequency == 'weekly' && task.repeatDays != null)
              Text(
                  'Days: ${task.repeatDays!.map((d) =>
                      DateFormat.E().format(DateTime(2020, 1, d))).join(
                      ', ')}'),
          ],
          if (!task.isCompleted) ...[
            Text('Due in: $timeRemainingText'),
          ],
          // Add Progress Bar
          LinearProgressIndicator(value: task.completionPercentage),
          Text('${(task.completionPercentage * 100).toStringAsFixed(
              0)}% Complete'),
        ],
      ),
      trailing: Checkbox(
        value: task.isCompleted,
        onChanged: (bool? value) {
          setState(() {
            _tasks[index].toggleCompletion(); // Toggle completion
            // If task is completed, set completion percentage to 100%
            if (value == true) {
              _tasks[index].completionPercentage = 1.0;
            } else {
              _tasks[index].completionPercentage = 0.0;
            }
          });
        },
      ),
    );
  }
}

  extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class EditTaskScreen extends StatefulWidget {
  final Task task;
  final Function(Task) onUpdate;
  final Function() onDelete;

  EditTaskScreen({required this.task, required this.onUpdate, required this.onDelete});

  @override
  _EditTaskScreenState createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _repeatFrequency;
  List<int> _repeatDays = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _selectedDate = DateTime.parse(widget.task.dueDate);
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
    _repeatFrequency = widget.task.repeatFrequency ?? 'none';
    _repeatDays = widget.task.repeatDays != null ? List.from(widget.task.repeatDays!) : [];
  }

  void _updateTask() {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    final updatedTask = Task(
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute).toIso8601String(),
      isRepeated: _repeatFrequency != 'none',
      isCompleted: widget.task.isCompleted,
      completionPercentage: widget.task.completionPercentage,
      repeatFrequency: _repeatFrequency,
      repeatDays: _repeatFrequency == 'weekly' ? _repeatDays : null,
    );

    widget.onUpdate(updatedTask);
    Navigator.pop(context);
  }

  void _deleteTask() {
    widget.onDelete();
    Navigator.pop(context);
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _toggleRepeatDay(int day) {
    setState(() {
      if (_repeatDays.contains(day)) {
        _repeatDays.remove(day);
      } else {
        _repeatDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Task'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteTask,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView( // Added to prevent overflow
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Task Title'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              ListTile(
                title: Text('Due Date: ${DateFormat('MMMM dd, yyyy').format(_selectedDate)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              // Time Picker
              ListTile(
                title: Text('Choose Time: ${_selectedTime.format(context)}'),
                trailing: Icon(Icons.access_time),
                onTap: _pickTime,
              ),
              // Repeat Frequency Selector
              DropdownButtonFormField<String>(
                value: _repeatFrequency,
                decoration: InputDecoration(labelText: 'Repeat Frequency'),
                items: [
                  DropdownMenuItem(child: Text('None'), value: 'none'),
                  DropdownMenuItem(child: Text('Daily'), value: 'daily'),
                  DropdownMenuItem(child: Text('Weekly'), value: 'weekly'),
                ],
                onChanged: (value) {
                  setState(() {
                    _repeatFrequency = value!;
                    if (_repeatFrequency != 'weekly') {
                      _repeatDays.clear();
                    }
                  });
                },
              ),
              // Day Selector for Weekly Repeats
              if (_repeatFrequency == 'weekly')
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Wrap(
                    children: List.generate(7, (index) {
                      return ChoiceChip(
                        label: Text(DateFormat.E().format(DateTime(2020, 1, index + 1))),
                        selected: _repeatDays.contains(index + 1),
                        onSelected: (selected) {
                          _toggleRepeatDay(index + 1);
                        },
                      );
                    }),
                  ),
                ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: ElevatedButton(
                  onPressed: _updateTask,
                  child: Text('Update Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddTaskScreen extends StatefulWidget {
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now(); // New variable for time
  String _repeatFrequency = 'none'; // 'none', 'daily', 'weekly'
  List<int> _repeatDays = [];

  void _addTask() {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    final task = Task(
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      ).toIso8601String(),
      isRepeated: _repeatFrequency != 'none',
      repeatFrequency: _repeatFrequency,
      repeatDays: _repeatFrequency == 'weekly' ? _repeatDays : null,
    );

    FocusScope.of(context).unfocus();

    Navigator.pop(context, task);
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _toggleRepeatDay(int day) {
    setState(() {
      if (_repeatDays.contains(day)) {
        _repeatDays.remove(day);
      } else {
        _repeatDays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Task'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Task Title'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              ListTile(
                title: Text('Due Date: ${DateFormat('MMMM dd, yyyy').format(_selectedDate)}'),
                trailing: Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              ListTile(
                title: Text('Due Time: ${_selectedTime.format(context)}'),
                trailing: Icon(Icons.access_time),
                onTap: _pickTime,
              ),
              // Repeat Frequency Selector
              DropdownButtonFormField<String>(
                value: _repeatFrequency,
                decoration: InputDecoration(labelText: 'Repeat Frequency'),
                items: [
                  DropdownMenuItem(child: Text('None'), value: 'none'),
                  DropdownMenuItem(child: Text('Daily'), value: 'daily'),
                  DropdownMenuItem(child: Text('Weekly'), value: 'weekly'),
                ],
                onChanged: (value) {
                  setState(() {
                    _repeatFrequency = value!;
                    if (_repeatFrequency != 'weekly') {
                      _repeatDays.clear();
                    }
                  });
                },
              ),
              // Day Selector for Weekly Repeats
              if (_repeatFrequency == 'weekly')
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Wrap(
                    spacing: 5,
                    children: List.generate(7, (index) {
                      final day = index + 1;
                      return ChoiceChip(
                        label: Text(DateFormat.E().format(DateTime(2020, 1, day + 6))),
                        selected: _repeatDays.contains(day),
                        onSelected: (selected) {
                          _toggleRepeatDay(day);
                        },
                      );
                    }),
                  ),
                ),
              SizedBox(height: 20),
              ElevatedButton(

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _addTask,
                child: Text('Add Task', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


