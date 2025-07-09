import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tasksy/view/screens/addTasks/add_task_view_model.dart';
import 'package:tasksy/view/screens/addTasks/widgets/custom_text_field.dart';
import 'package:tasksy/view/screens/addTasks/widgets/priority_selector.dart';
import 'package:tasksy/view/screens/addTasks/widgets/date_time_picker.dart';

class AddTaskScreen extends StatelessWidget {
  final AddTaskViewModel controller = Get.put(AddTaskViewModel());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Add New Task',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomTextField(
              label: 'Task Title',
              hint: 'Enter task title',
              prefixIcon: Icons.title,
              onChanged: (value) => controller.title.value = value,
            ),
            CustomTextField(
              label: 'Description',
              hint: 'Enter task description',
              prefixIcon: Icons.description,
              maxLines: 3,
              onChanged: (value) => controller.description.value = value,
            ),
            Obx(() => PrioritySelector(
                  selectedPriority: controller.priority.value,
                  onPriorityChanged: (priority) =>
                      controller.priority.value = priority,
                )),
            Obx(() => DateTimePicker(
                  selectedDate: controller.dueDate.value,
                  selectedTime: controller.dueTime.value,
                  onDateChanged: (date) => controller.dueDate.value = date,
                  onTimeChanged: (time) => controller.dueTime.value = time,
                )),
            const SizedBox(height: 20),
            Obx(() => CustomButton(
                  text: 'Create Task',
                  icon: Icons.add_task,
                  isLoading: controller.isLoading.value,
                  onPressed: () {
                    controller.addTask();
                    Get.back();
                  },
                )),
          ],
        ),
      ),
    );
  }
}
