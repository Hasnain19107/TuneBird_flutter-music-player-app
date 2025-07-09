import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tasksy/view/screens/hom/home_view_model.dart';
import 'package:tasksy/view/screens/hom/widgets/empty_state_widget.dart';
import 'package:tasksy/view/screens/hom/widgets/task_item_widget.dart';

class TaskListWidget extends StatelessWidget {
  final HomeViewModel controller;

  const TaskListWidget({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.taskList.isEmpty) {
        return const EmptyStateWidget();
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: controller.taskList.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return TaskItemWidget(
            task: controller.taskList[index],
            onDelete: () => controller.deleteTask(index),
            onToggleComplete: () {
              controller.toggleTaskCompletion(index);
            },
          );
        },
      );
    });
  }
}
