import 'dart:async';

import 'package:get/get.dart';

class PomodoroViewModels extends GetxController {
  var timerElapsed = 0.obs; // Time elapsed in seconds, starts from 0
  var isRunning = false.obs;
  var isPaused = false.obs;
  Timer? _timer;
  
  void start() {
    if (isRunning.value) return;
    
    isRunning.value = true;
    isPaused.value = false;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      timerElapsed.value++; // Count up indefinitely
    });
  }

  void pause() {
    if (!isRunning.value) return;
    
    _timer?.cancel();
    isRunning.value = false;
    isPaused.value = true;
  }
  
  void resume() {
    if (!isPaused.value) return;
    
    isPaused.value = false;
    start(); // Reuse the start logic
  }
  
  void stop() {
    _timer?.cancel();
    timerElapsed.value = 0; // Reset to 0
    isRunning.value = false;
    isPaused.value = false;
  }

  void reset() {
    _timer?.cancel();
    timerElapsed.value = 0; // Reset to 0
    isRunning.value = false;
    isPaused.value = false;
  }
  
  // Format elapsed time for display (MM:SS)
  String get formattedTime {
    int minutes = timerElapsed.value ~/ 60;
    int seconds = timerElapsed.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  // Get elapsed time in hours, minutes, seconds for long sessions
  String get formattedTimeWithHours {
    int hours = timerElapsed.value ~/ 3600;
    int minutes = (timerElapsed.value % 3600) ~/ 60;
    int seconds = timerElapsed.value % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
  
  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
