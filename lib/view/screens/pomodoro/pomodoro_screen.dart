import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tasksy/view/screens/pomodoro/pomodoro_view_models.dart';

class PomodoroScreen extends StatelessWidget {
  final controller = Get.put(PomodoroViewModels());
  PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Timer',
          style: TextStyle(color: Colors.black, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Obx(() {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _getStatusColor()),
                ),
                child: Text(
                  _getStatusText(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _getStatusColor(),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Main timer display
              Text(
                controller.formattedTimeWithHours,
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),

              const SizedBox(height: 8),

              // Elapsed time label
              const Text(
                'Elapsed Time',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 60),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Start/Resume button
                  ElevatedButton.icon(
                    onPressed: controller.isRunning.value
                        ? null
                        : (controller.isPaused.value
                            ? controller.resume
                            : controller.start),
                    icon: Icon(controller.isPaused.value
                        ? Icons.play_arrow
                        : Icons.play_arrow),
                    label: Text(controller.isPaused.value ? 'Resume' : 'Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Pause button
                  ElevatedButton.icon(
                    onPressed:
                        controller.isRunning.value ? controller.pause : null,
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Stop button
                  ElevatedButton.icon(
                    onPressed: (controller.isRunning.value ||
                            controller.isPaused.value)
                        ? controller.stop
                        : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Reset button (separate row for better layout)
              ElevatedButton.icon(
                onPressed: controller.reset,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Color _getStatusColor() {
    if (controller.isRunning.value) return Colors.green;
    if (controller.isPaused.value) return Colors.orange;
    return Colors.grey;
  }

  String _getStatusText() {
    if (controller.isRunning.value) return '⏱️ Running';
    if (controller.isPaused.value) return '⏸️ Paused';
    if (controller.timerElapsed.value > 0) return '⏹️ Stopped';
    return '🚀 Ready';
  }
}
