import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Premium text field with custom styling, prefix icon, and currency input support.
class ProTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? maxLength;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool readOnly;
  final VoidCallback? onTap;

  const ProTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffix,
    this.validator,
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.obscureText = false,
    this.onChanged,
    this.focusNode,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 8),
        ],
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          maxLength: maxLength,
          obscureText: obscureText,
          onChanged: onChanged,
          focusNode: focusNode,
          readOnly: readOnly,
          onTap: onTap,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 22)
                : null,
            suffix: suffix,
            counterText: '', // Hide max length counter
          ),
        ),
      ],
    );
  }
}
