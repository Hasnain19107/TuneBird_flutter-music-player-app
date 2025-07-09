import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tasksy/routes/Routes.dart';
import 'package:tasksy/view/screens/hom/home_view_model.dart';
import 'package:tasksy/view/screens/hom/widgets/task_list_widget.dart';
import 'package:tasksy/view/screens/hom/widgets/floating_action_buttons.dart';
import 'package:tasksy/view/screens/hom/widgets/home_app_bar.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Get.put to ensure the controller is properly initialized
    final controller = Get.put(HomeViewModel());
    
    return Scaffold(
      appBar: const HomeAppBar(),
      body: TaskListWidget(controller: controller),
      floatingActionButton: const FloatingActionButtons(),
    );
  }
}
