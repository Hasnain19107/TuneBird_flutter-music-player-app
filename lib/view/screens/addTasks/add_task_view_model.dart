import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tasksy/data/models/task_model.dart';
import 'package:tasksy/view/screens/hom/home_view_model.dart';
import 'package:uuid/uuid.dart';

class AddTaskViewModel extends GetxController {
  var title = ''.obs;
  var description = ''.obs;
  var priority = 'Medium'.obs;
  var dueDate = Rxn<DateTime>();
  var dueTime = Rxn<TimeOfDay>();
  var isLoading = false.obs;

  Future<void> addTask() async {
    if (title.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a task title',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    if (description.value.isEmpty) {
      Get.snackbar(
        'Error',
        'Please enter a task description',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    isLoading.value = true;

    try {
      // Combine date and time if both are selected
      DateTime? finalDueDate;
      if (dueDate.value != null) {
        if (dueTime.value != null) {
          finalDueDate = DateTime(
            dueDate.value!.year,
            dueDate.value!.month,
            dueDate.value!.day,
            dueTime.value!.hour,
            dueTime.value!.minute,
          );
        } else {
          finalDueDate = dueDate.value;
        }
      }

      final task = TaskModel(
        id: const Uuid().v4(),
        title: title.value.trim(),
        description: description.value.trim(),
        priority: priority.value,
        dueDate: finalDueDate,
        createdAt: DateTime.now(),
        isCompleted: false,
      );

      // Get or create HomeViewModel instance
      final homeController = Get.find<HomeViewModel>();
      await homeController.addTask(task);

      Get.snackbar(
        'Success',
        'Task created successfully!',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade800,
        snackPosition: SnackPosition.TOP,
      );

      clearForm();
      Get.back();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to create task: ${e.toString()}',
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    title.value = '';
    description.value = '';
    priority.value = 'Medium';
    dueDate.value = null;
    dueTime.value = null;
  }

  @override
  void onClose() {
    clearForm();
    super.onClose();
  }
}
