import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:tasksy/view/screens/addTasks/add_task_view_model.dart';
import 'package:tasksy/view/screens/hom/home_view_model.dart';
import 'package:tasksy/view/screens/pomodoro/pomodoro_view_models.dart';

class Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeViewModel>(() => HomeViewModel());
    Get.lazyPut<AddTaskViewModel>(() => AddTaskViewModel());
    Get.put<PomodoroViewModels>(PomodoroViewModels(), permanent: true);
  }
}
