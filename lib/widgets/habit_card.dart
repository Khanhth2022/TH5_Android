import 'package:flutter/material.dart';

class HabitCard extends StatelessWidget {
  final IconData icon;
  final String name;
  final String time;
  final bool completed;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HabitCard({
    Key? key,
    required this.icon,
    required this.name,
    required this.time,
    this.completed = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: completed ? 4 : 1,
      color: completed ? Colors.green[100] : null,
      child: ListTile(
        leading: Icon(icon, color: completed ? Colors.green : null),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: completed ? Colors.green[900] : null,
          ),
        ),
        subtitle: Text('Khung giờ: $time'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
