import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:tasksy/data/models/task_model.dart';

class HomeViewModel extends GetxController {
  var taskList = <TaskModel>[].obs;
  var filterType = 'All'.obs;
  late Box<TaskModel> _taskBox;

  @override
  void onInit() {
    super.onInit();
    _initHive();
  }

  Future<void> _initHive() async {
    _taskBox = Hive.box<TaskModel>('tasks');
    _loadTasks();
  }

  void _loadTasks() {
    final tasks = _taskBox.values.toList();
    taskList.assignAll(tasks);
  }

  Future<void> addTask(TaskModel task) async {
    try {
      await _taskBox.put(task.id, task);
      taskList.add(task);
      update();
    } catch (e) {
      print('Error adding task: $e');
    }
  }

  Future<void> toggleTaskCompletion(int index) async {
    if (index >= 0 && index < taskList.length) {
      final task = taskList[index];
      task.isCompleted = !task.isCompleted;
      
      try {
        await _taskBox.put(task.id, task);
        taskList.refresh();
        update();
      } catch (e) {
        print('Error updating task: $e');
      }
    }
  }

  Future<void> deleteTask(int index) async {
    if (index >= 0 && index < taskList.length) {
      final task = taskList[index];
      
      try {
        await _taskBox.delete(task.id);
        taskList.removeAt(index);
        update();
      } catch (e) {
        print('Error deleting task: $e');
      }
    }
  }

  void setFilter(String filter) {
    filterType.value = filter;
  }

  List<TaskModel> get filteredTasks {
    switch (filterType.value) {
      case 'Completed':
        return taskList.where((task) => task.isCompleted).toList();
      case 'Pending':
        return taskList.where((task) => !task.isCompleted).toList();
      case 'High':
        return taskList.where((task) => task.priority == 'High').toList();
      case 'Medium':
        return taskList.where((task) => task.priority == 'Medium').toList();
      case 'Low':
        return taskList.where((task) => task.priority == 'Low').toList();
      default:
        return taskList;
    }
  }

  List<TaskModel> get sortedTasks {
    final filtered = filteredTasks;
    filtered.sort((a, b) {
      // Sort by completion status first (incomplete tasks first)
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      
      // Then by priority
      const priorityOrder = {'High': 0, 'Medium': 1, 'Low': 2};
      final aPriority = priorityOrder[a.priority] ?? 3;
      final bPriority = priorityOrder[b.priority] ?? 3;
      
      if (aPriority != bPriority) {
        return aPriority.compareTo(bPriority);
      }
      
      // Finally by due date (earliest first)
      if (a.dueDate != null && b.dueDate != null) {
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (a.dueDate != null) {
        return -1;
      } else if (b.dueDate != null) {
        return 1;
      }
      
      // If all else is equal, sort by created date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });
    
    return filtered;
  }

  int get totalTasks => taskList.length;
  int get completedTasks => taskList.where((task) => task.isCompleted).length;
  int get pendingTasks => taskList.where((task) => !task.isCompleted).length;
  int get overdueTasks => taskList.where((task) => 
    !task.isCompleted && 
    task.dueDate != null && 
    task.dueDate!.isBefore(DateTime.now())
  ).length;

  @override
  void onClose() {
    _taskBox.close();
    super.onClose();
  }
}
