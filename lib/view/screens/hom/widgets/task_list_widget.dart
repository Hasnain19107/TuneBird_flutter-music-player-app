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
      final tasks = controller.sortedTasks;
      
      if (tasks.isEmpty) {
        return const EmptyStateWidget();
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final task = tasks[index];
          final originalIndex = controller.taskList.indexOf(task);
          
          return TaskItemWidget(
            task: task,
            onDelete: () => controller.deleteTask(originalIndex),
            onToggleComplete: () => controller.toggleTaskCompletion(originalIndex),
          );
        },
      );
    });
  }
}
