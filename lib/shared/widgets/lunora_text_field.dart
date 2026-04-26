import 'package:flutter/material.dart';

class LunoraTextField extends StatelessWidget {
  const LunoraTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.textInputAction,
    this.validator,
    this.maxLines = 1,
    this.minLines,
  });

  final TextEditingController controller;
  final String? label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final String? Function(String? value)? validator;
  final int maxLines;
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType ??
          (maxLines > 1 ? TextInputType.multiline : null),
      obscureText: obscureText,
      textInputAction:
          maxLines > 1 ? TextInputAction.newline : textInputAction,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }
}
