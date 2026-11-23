import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomOtpInput extends StatefulWidget {
  final int length;
  final void Function(String)? onChanged;
  final void Function(String)? onCompleted;

  const CustomOtpInput({super.key, this.length = 6, this.onChanged, this.onCompleted});

  @override
  State<CustomOtpInput> createState() => _CustomOtpInputState();
}

class _CustomOtpInputState extends State<CustomOtpInput> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (index) => FocusNode());
    _controllers = List.generate(widget.length, (index) => TextEditingController());
  }

  @override
  void dispose() {
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _getOtpString() {
    return _controllers.map((c) => c.text).join();
  }

  void _onChanged(String value, int index) {
    // Logic tiến/lùi con trỏ Focus
    if (value.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Gọi callbacks trả dữ liệu về cho màn hình cha
    final otpCode = _getOtpString();
    if (widget.onChanged != null) {
      widget.onChanged!(otpCode);
    }
    if (otpCode.length == widget.length && widget.onCompleted != null) {
      widget.onCompleted!(otpCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        widget.length,
        (index) => SizedBox(
          width: 45, // Bạn có thể linh hoạt sửa kích thước nếu cần
          height: 55,
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: colorScheme.surfaceContainer, // Khớp với CustomTextField
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
              ),
            ),
            onChanged: (value) => _onChanged(value, index),
          ),
        ),
      ),
    );
  }
}
