import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tasksy/routes/Routes.dart';

class FloatingActionButtons extends StatelessWidget {
  const FloatingActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildFAB(
          onPressed: () => Get.toNamed(Routes.addTask),
          heroTag: "add",
          icon: Icons.add,
          tooltip: 'Add Task',
          backgroundColor: Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildFAB(
          onPressed: () => Get.toNamed(Routes.pomodoro),
          heroTag: "pomodoro",
          icon: Icons.timer,
          tooltip: 'Pomodoro Timer',
          backgroundColor: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildFAB({
    required VoidCallback onPressed,
    required String heroTag,
    required IconData icon,
    required String tooltip,
    required Color backgroundColor,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      heroTag: heroTag,
      tooltip: tooltip,
      backgroundColor: backgroundColor,
      elevation: 6,
      child: Icon(
        icon,
        color: Colors.white,
      ),
    );
  }
}