import 'package:flutter/material.dart';
import 'todo_list.dart';
import 'dashboard.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Productivity Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/todo': (context) => Scaffold(
          appBar: AppBar(
            title: const Text('My Todo List'),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          ),
          body: const TodoList(),
        ),
      },
    );
  }
}
