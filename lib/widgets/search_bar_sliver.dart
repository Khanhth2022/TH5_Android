import 'package:flutter/material.dart';

/// A simple sliver search bar widget for use in CustomScrollView.
class SearchBarSliver extends StatelessWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;

  const SearchBarSliver({
    Key? key,
    this.hintText = 'Tìm kiếm...',
    this.onChanged,
    this.onClear,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            suffixIcon: onClear != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Xóa tìm kiếm',
                    onPressed: onClear,
                  )
                : null,
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant,
          ),
        ),
      ),
    );
  }
}
