import 'package:flutter/material.dart';

class ElunaiTextField extends StatefulWidget {
  const ElunaiTextField({
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
  State<ElunaiTextField> createState() => _ElunaiTextFieldState();
}

class _ElunaiTextFieldState extends State<ElunaiTextField> {
  late bool _hidden = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final obscure = widget.obscureText && _hidden;
    return TextFormField(
      controller: widget.controller,
      keyboardType:
          widget.keyboardType ??
          (widget.maxLines > 1 ? TextInputType.multiline : null),
      obscureText: obscure,
      textInputAction: widget.maxLines > 1
          ? TextInputAction.newline
          : widget.textInputAction,
      validator: widget.validator,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        suffixIcon: widget.obscureText
            ? IconButton(
                tooltip: _hidden
                    ? 'Afficher le mot de passe'
                    : 'Masquer le mot de passe',
                icon: Icon(
                  _hidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : null,
      ),
    );
  }
}
