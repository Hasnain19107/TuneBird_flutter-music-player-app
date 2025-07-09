import 'package:flutter/material.dart';

class PrioritySelector extends StatelessWidget {
  final String selectedPriority;
  final Function(String) onPriorityChanged;

  const PrioritySelector({
    Key? key,
    required this.selectedPriority,
    required this.onPriorityChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final priorities = ['Low', 'Medium', 'High'];
    final priorityColors = {
      'Low': Colors.green,
      'Medium': Colors.orange,
      'High': Colors.red,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Priority',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: priorities.map((priority) {
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => onPriorityChanged(priority),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedPriority == priority
                            ? priorityColors[priority]
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: priorityColors[priority]!,
                          width: selectedPriority == priority ? 0 : 1,
                        ),
                      ),
                      child: Text(
                        priority,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selectedPriority == priority
                              ? Colors.white
                              : priorityColors[priority],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}