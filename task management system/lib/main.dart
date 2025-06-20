import 'package:flutter/material.dart';
import 'task_page.dart';
import 'notification_util.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  NotificationUtil.initialize();
  runApp(TaskManagerApp());
}

class TaskManagerApp extends StatefulWidget {
  @override
  _TaskManagerAppState createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  bool _isDarkTheme = false;

  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
    });
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness: _isDarkTheme ? Brightness.dark : Brightness.light,
      primaryColor: _isDarkTheme ? Colors.teal[850] : Colors.teal,
      appBarTheme: AppBarTheme(
        backgroundColor: _isDarkTheme ? Colors.teal[900] : Colors.teal,
      ),
      scaffoldBackgroundColor: _isDarkTheme ? Colors.grey[900] : Colors.grey[50],
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _isDarkTheme ? Colors.teal : Colors.teal,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: _isDarkTheme ? Colors.white : Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: _buildTheme(),
      home: TaskListScreen(onThemeToggle: _toggleTheme),

    );
  }
}
