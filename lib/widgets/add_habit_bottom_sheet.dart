import 'package:flutter/material.dart';
import 'package:time_picker/time_picker.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../services/string_matching_service.dart';

class AddHabitBottomSheet extends StatefulWidget {
  const AddHabitBottomSheet({Key? key}) : super(key: key);

  @override
  State<AddHabitBottomSheet> createState() => _AddHabitBottomSheetState();
}

class _AddHabitBottomSheetState extends State<AddHabitBottomSheet> {
  TimeOfDay? _selectedTime;
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final List<String> _existingHabits = [
    'Uống nước',
    'Chạy bộ',
    'Đọc sách',
    'Thiền',
    'Tập gym',
  ]; // TODO: Lấy từ Provider thực tế

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  bool _isNameSimilar(String input) {
    for (final habit in _existingHabits) {
      final sim = StringMatchingService.normalizedSimilarity(input, habit);
      if (sim >= 0.9) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Thêm thói quen mới',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              // Tên thói quen (bắt buộc, auto-suggest, kiểm tra trùng)
              TypeAheadFormField<String>(
                textFieldConfiguration: TextFieldConfiguration(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tên thói quen *',
                    border: OutlineInputBorder(),
                  ),
                ),
                suggestionsCallback: (pattern) {
                  return _existingHabits.where((h) => h.toLowerCase().contains(pattern.toLowerCase()));
                },
                itemBuilder: (context, suggestion) {
                  return ListTile(title: Text(suggestion));
                },
                onSuggestionSelected: (suggestion) {
                  _nameController.text = suggestion;
                },
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Tên thói quen không được để trống';
                  }
                  if (_isNameSimilar(value.trim())) {
                    return 'Tên thói quen đã tồn tại hoặc quá giống!';
                  }
                  return null;
                },
                onSaved: (value) {},
              ),
              const SizedBox(height: 12),
              // Mô tả (cho phép bỏ trống)
              TextField(
                decoration: InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              // Lịch thực hiện: Dải nút bấm (Thứ 2 đến CN)
              const Text('Lịch thực hiện:', style: TextStyle(fontWeight: FontWeight.w600)),
              _WeekdaySelector(),
              const SizedBox(height: 12),
              // Số lần lặp
              Row(
                children: [
                  const Text('Số lần lặp/ngày:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
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
                  const Text('Khung giờ:', style: TextStyle(fontWeight: FontWeight.w600)),
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
                  onPressed: () {
                    final name = _nameController.text.trim();
                    if (_isNameSimilar(name)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tên thói quen đã tồn tại hoặc quá giống!')), 
                      );
                      return;
                    }
                    // TODO: Lưu thói quen mới
                  },
                  child: const Text('Lưu'),
                ),
              ),
              // Nút xóa (ví dụ, dùng cho sửa/xóa thói quen)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Xóa thói quen', style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    final confirm = await showCommonAlertDialog(
                      context,
                      title: 'Xác nhận xóa',
                      content: 'Bạn có chắc chắn muốn xóa thói quen này? Mọi chuỗi (Streak) sẽ bị mất!',
                      confirmText: 'Xóa',
                      cancelText: 'Hủy',
                    );
                    if (confirm == true) {
                      // TODO: Xóa thói quen
                    }
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
  const _WeekdaySelector({Key? key}) : super(key: key);

  @override
  State<_WeekdaySelector> createState() => _WeekdaySelectorState();
}

class _WeekdaySelectorState extends State<_WeekdaySelector> {
  final List<bool> _selected = List.generate(7, (_) => false);
  final List<String> _labels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        return ChoiceChip(
          label: Text(_labels[i]),
          selected: _selected[i],
          onSelected: (selected) {
            setState(() {
              _selected[i] = selected;
            });
          },
        );
      }),
    );
  }
}
