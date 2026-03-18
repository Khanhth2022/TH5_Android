import 'package:flutter/material.dart';

class ExpandableCheckbox extends StatefulWidget {
  final int repeatCount;
  final List<bool> checkedList;
  final ValueChanged<List<bool>> onChanged;

  const ExpandableCheckbox({
    Key? key,
    required this.repeatCount,
    required this.checkedList,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<ExpandableCheckbox> createState() => _ExpandableCheckboxState();
}

class _ExpandableCheckboxState extends State<ExpandableCheckbox> {
  late List<bool> _checked;

  @override
  void initState() {
    super.initState();
    _checked = List<bool>.from(widget.checkedList);
  }

  @override
  void didUpdateWidget(covariant ExpandableCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.checkedList != widget.checkedList) {
      _checked = List<bool>.from(widget.checkedList);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(widget.repeatCount, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _checked[i] = !_checked[i];
              });
              widget.onChanged(_checked);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _checked[i] ? Colors.green : Colors.transparent,
                border: Border.all(color: Colors.green, width: 2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: _checked[i]
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
        );
      }),
    );
  }
}
