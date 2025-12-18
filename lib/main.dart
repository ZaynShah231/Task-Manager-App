import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/task.dart';
import 'models/event.dart';

import 'screens/home_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/events_screen.dart';

Future<void> initializeStorage() async {
  await Hive.initFlutter();

  if (!Hive.isAdapterRegistered(TaskAdapter().typeId)) {
    Hive.registerAdapter(TaskAdapter());
  }

  if (!Hive.isAdapterRegistered(EventAdapter().typeId)) {
    Hive.registerAdapter(EventAdapter());
  }

  await Future.wait([
    Hive.openBox<Task>('tasks'),
    Hive.openBox<Event>('events'),
  ]);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeStorage();
  runApp(const TodoApplication());
}

class TodoApplication extends StatelessWidget {
  const TodoApplication({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      routes: _appRoutes,
      initialRoute: HomeScreen.routeName,
    );
  }
}

final Map<String, WidgetBuilder> _appRoutes = {
  HomeScreen.routeName: (context) => const HomeScreen(),
  TasksScreen.routeName: (context) => const TasksScreen(),
  EventsScreen.routeName: (context) => const EventsScreen(),
};
