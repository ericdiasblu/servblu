import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';

class InputField extends StatefulWidget {
  final IconData? icon;
  final String hintText;
  final TextEditingController? controller;
  final MaskedTextController? maskedController;
  final EdgeInsetsGeometry? margin;
  final bool obscureText;
  final bool isDescription;
  final bool isPassword;

  const InputField({
    Key? key,
    this.icon,
    required this.hintText,
    required this.obscureText,
    this.controller,
    this.maskedController,
    this.margin,
    this.isDescription = false,
    this.isPassword = false,
  }) : super(key: key);

  @override
  State<InputField> createState() => _InputFieldState();
}

class _InputFieldState extends State<InputField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF017DFE),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      margin: widget.margin ?? const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: widget.isDescription ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (!widget.isDescription)
            Icon(widget.icon, color: const Color(0xFF017DFE)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              obscureText: _obscureText,
              controller: widget.maskedController ?? widget.controller,
              maxLines: widget.isDescription ? 5 : 1,
              decoration: InputDecoration(
                hintText: widget.hintText,
                border: InputBorder.none,
                hintStyle: const TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (widget.isPassword)
            IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.grey,
              ),
              onPressed: _toggleVisibility,
            ),
        ],
      ),
    );
  }
}
