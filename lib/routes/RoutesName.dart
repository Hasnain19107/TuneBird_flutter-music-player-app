import 'package:get/get.dart';
import 'package:tasksy/bindings/binding.dart';
import 'package:tasksy/routes/Routes.dart';
import 'package:tasksy/view/screens/addTasks/add_task_screen.dart';
import 'package:tasksy/view/screens/hom/home_screen.dart';
import 'package:tasksy/view/screens/pomodoro/pomodoro_screen.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: Routes.home,
      page: () => HomeScreen(),
      binding: Binding(),
    ),
    GetPage(
      name: Routes.addTask,
      page: () => AddTaskScreen(),
      binding: Binding(),
    ),
    GetPage(
      name: Routes.pomodoro,
      page: () => PomodoroScreen(),
      binding: Binding(),
    ),
  ];
}
