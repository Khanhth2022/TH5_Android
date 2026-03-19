import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import '../services/string_matching_service.dart';
import 'common_alert_dialog.dart';

class AddHabitBottomSheet extends StatefulWidget {
  const AddHabitBottomSheet({Key? key, this.initialHabit}) : super(key: key);

  final Habit? initialHabit;

  @override
  State<AddHabitBottomSheet> createState() => _AddHabitBottomSheetState();
}

class _AddHabitBottomSheetState extends State<AddHabitBottomSheet> {
  TimeOfDay? _selectedTime;
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _repeatController = TextEditingController(
    text: '1',
  );
  Set<int> _selectedWeekdays = <int>{1, 2, 3, 4, 5, 6, 7};
  bool _isSaving = false;
  String? _nameError;

  bool get _isEditMode => widget.initialHabit != null;

  @override
  void initState() {
    super.initState();
    final habit = widget.initialHabit;
    if (habit == null) return;

    _nameController.text = habit.name;
    _descriptionController.text = habit.description ?? '';
    _repeatController.text = habit.targetCountPerDay.toString();
    _selectedWeekdays = habit.activeWeekdays.isEmpty
        ? <int>{1, 2, 3, 4, 5, 6, 7}
        : Set<int>.from(habit.activeWeekdays);

    if (habit.reminderMinutesFromMidnight != null) {
      final minutes = habit.reminderMinutesFromMidnight!;
      _selectedTime = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
      _timeController.text = _formatTime(_selectedTime!);
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    _descriptionController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  bool _isNameSimilar(String input, Iterable<String> existingNames) {
    for (final habit in existingNames) {
      final sim = StringMatchingService.normalizedSimilarity(input, habit);
      if (sim >= 0.9) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HabitProvider>();
    final existingNames = provider.habits.map((habit) => habit.name).where((
      name,
    ) {
      if (!_isEditMode) return true;
      return name.toLowerCase() !=
          widget.initialHabit!.name.trim().toLowerCase();
    }).toList();

    return Material(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _isEditMode ? 'Sửa thói quen' : 'Thêm thói quen mới',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                onChanged: (_) {
                  if (_nameError != null) {
                    setState(() {
                      _nameError = null;
                    });
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Tên thói quen *',
                  border: const OutlineInputBorder(),
                  errorText: _nameError,
                ),
              ),
              const SizedBox(height: 12),
              // Mô tả (cho phép bỏ trống)
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              // Lịch thực hiện: Dải nút bấm (Thứ 2 đến CN)
              const Text(
                'Lịch thực hiện:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              _WeekdaySelector(
                selectedWeekdays: _selectedWeekdays,
                onChanged: (value) {
                  setState(() {
                    _selectedWeekdays = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Số lần lặp
              Row(
                children: [
                  const Text(
                    'Số lần lặp/ngày:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _repeatController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'VD: 1, 4...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Khung giờ
              Row(
                children: [
                  const Text(
                    'Khung giờ:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _selectedTime ?? TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedTime = picked;
                            _timeController.text = picked.format(context);
                          });
                        }
                      },
                      child: AbsorbPointer(
                        child: TextField(
                          controller: _timeController,
                          decoration: const InputDecoration(
                            hintText: 'Chọn giờ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Nút lưu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          final name = _nameController.text.trim();
                          if (name.isEmpty) {
                            setState(() {
                              _nameError = 'Tên thói quen không được để trống';
                            });
                            return;
                          }

                          if (_isNameSimilar(name, existingNames)) {
                            setState(() {
                              _nameError =
                                  'Tên thói quen đã tồn tại hoặc quá giống!';
                            });
                            return;
                          }

                          final repeatCount =
                              int.tryParse(_repeatController.text.trim()) ?? 1;
                          if (repeatCount <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Số lần lặp phải lớn hơn 0'),
                              ),
                            );
                            return;
                          }

                          final reminderMinutes = _selectedTime == null
                              ? null
                              : (_selectedTime!.hour * 60 +
                                    _selectedTime!.minute);

                          final habit = Habit(
                            id:
                                widget.initialHabit?.id ??
                                'habit_${DateTime.now().millisecondsSinceEpoch}',
                            name: name,
                            description:
                                _descriptionController.text.trim().isEmpty
                                ? null
                                : _descriptionController.text.trim(),
                            iconCodePoint: widget.initialHabit?.iconCodePoint,
                            iconFontFamily: widget.initialHabit?.iconFontFamily,
                            targetCountPerDay: repeatCount,
                            activeWeekdays: _selectedWeekdays.isEmpty
                                ? <int>{1, 2, 3, 4, 5, 6, 7}
                                : _selectedWeekdays,
                            reminderMinutesFromMidnight: reminderMinutes,
                            createdAt:
                                widget.initialHabit?.createdAt ??
                                DateTime.now(),
                            progressByDate: widget.initialHabit?.progressByDate,
                          );

                          setState(() {
                            _isSaving = true;
                          });

                          final habitProvider = context.read<HabitProvider>();
                          if (_isEditMode) {
                            await habitProvider.updateHabit(habit);
                          } else {
                            await habitProvider.addHabit(habit);
                          }

                          if (!mounted) return;

                          setState(() {
                            _isSaving = false;
                          });

                          final existsInProvider = habitProvider.habits.any(
                            (item) => item.id == habit.id,
                          );
                          if (!existsInProvider) {
                            final error = habitProvider.errorMessage;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  error == null
                                      ? 'Lưu thất bại, vui lòng thử lại'
                                      : 'Lưu thất bại: $error',
                                ),
                              ),
                            );
                            return;
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isEditMode
                                    ? 'Đã cập nhật thói quen'
                                    : 'Đã lưu thói quen mới',
                              ),
                            ),
                          );
                          Navigator.of(context).pop(true);
                        },
                  child: Text(
                    _isSaving
                        ? 'Đang lưu...'
                        : (_isEditMode ? 'Cập nhật' : 'Lưu'),
                  ),
                ),
              ),
              if (_isEditMode)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text(
                      'Xóa thói quen',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () async {
                      final confirm = await showCommonAlertDialog(
                        context,
                        title: 'Xác nhận xóa',
                        content:
                            'Bạn có chắc chắn muốn xóa thói quen này? Mọi chuỗi (Streak) sẽ bị mất!',
                        confirmText: 'Xóa',
                        cancelText: 'Hủy',
                      );
                      if (confirm != true) return;

                      await context.read<HabitProvider>().deleteHabit(
                        widget.initialHabit!.id,
                      );
                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đã xóa thói quen')),
                      );
                      Navigator.of(context).pop(true);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget chọn nhiều ngày trong tuần
class _WeekdaySelector extends StatefulWidget {
  const _WeekdaySelector({
    Key? key,
    required this.selectedWeekdays,
    required this.onChanged,
  }) : super(key: key);

  final Set<int> selectedWeekdays;
  final ValueChanged<Set<int>> onChanged;

  @override
  State<_WeekdaySelector> createState() => _WeekdaySelectorState();
}

class _WeekdaySelectorState extends State<_WeekdaySelector> {
  final List<String> _labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final weekday = i + 1;
        return ChoiceChip(
          label: Text(_labels[i]),
          selected: widget.selectedWeekdays.contains(weekday),
          onSelected: (selected) {
            final next = Set<int>.from(widget.selectedWeekdays);
            if (selected) {
              next.add(weekday);
            } else {
              next.remove(weekday);
            }
            widget.onChanged(next);
          },
        );
      }),
    );
  }
}
