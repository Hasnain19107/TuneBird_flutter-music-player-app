// main.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tasksy/data/models/task_model.dart';
import 'package:tasksy/routes/Routes.dart';
import 'package:tasksy/routes/RoutesName.dart';
import 'package:tasksy/view/screens/hom/home_view_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(TaskModelAdapter());

  // Open boxes
  await Hive.openBox<TaskModel>('tasks');

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tasksy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: Routes.home,
      getPages: AppPages.pages,
    );
  }
}
