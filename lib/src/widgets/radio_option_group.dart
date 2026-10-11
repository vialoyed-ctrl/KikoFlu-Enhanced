import 'package:flutter/material.dart';

class RadioOption<T> {
  const RadioOption({
    required this.value,
    required this.title,
    this.subtitle,
    this.selected,
    this.enabled,
  });

  final T value;
  final Widget title;
  final Widget? subtitle;
  final bool? selected;
  final bool? enabled;
}

class RadioOptionGroup<T> extends StatelessWidget {
  const RadioOptionGroup({
    super.key,
    required this.groupValue,
    required this.options,
    required this.onChanged,
    this.mainAxisSize = MainAxisSize.min,
    this.dense,
    this.contentPadding,
  });

  final T? groupValue;
  final List<RadioOption<T>> options;
  final ValueChanged<T> onChanged;
  final MainAxisSize mainAxisSize;
  final bool? dense;
  final EdgeInsetsGeometry? contentPadding;

  @override
  Widget build(BuildContext context) {
    return RadioGroup<T>(
      groupValue: groupValue,
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
      child: Column(
        mainAxisSize: mainAxisSize,
        children: [
          for (final option in options)
            RadioListTile<T>(
              title: option.title,
              subtitle: option.subtitle,
              value: option.value,
              selected: option.selected ?? option.value == groupValue,
              enabled: option.enabled,
              dense: dense,
              contentPadding: contentPadding,
            ),
        ],
      ),
    );
  }
}
