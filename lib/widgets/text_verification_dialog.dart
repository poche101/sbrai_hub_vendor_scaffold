import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Describes one additional field beyond the primary value — used for
/// steps like driver's-license/passport verification where the backend
/// requires more than just a document number (e.g. date of birth, last
/// name).
class ExtraField {
  final String key;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final String? Function(String value)? validator;

  const ExtraField({
    required this.key,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.validator,
  });
}

/// A clean verification dialog for document/number-based KYC steps (NIN,
/// BVN, driver's license, passport, CAC) — proper label, hint, live
/// validation, and an inline loading/error state instead of a bare text
/// prompt. Supports optional [extraFields] for steps that need more than
/// one value.
class TextVerificationDialog extends StatefulWidget {
  final String title;
  final String label;
  final String hint;
  final TextInputType keyboardType;
  final int? maxLength;
  final String? Function(String value)? validator;
  final List<ExtraField> extraFields;
  final Future<void> Function(String value, Map<String, String> extra) onSubmit;

  const TextVerificationDialog({
    super.key,
    required this.title,
    required this.label,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.validator,
    this.extraFields = const [],
    required this.onSubmit,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? Function(String value)? validator,
    List<ExtraField> extraFields = const [],
    required Future<void> Function(String value, Map<String, String> extra) onSubmit,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => TextVerificationDialog(
        title: title,
        label: label,
        hint: hint,
        keyboardType: keyboardType,
        maxLength: maxLength,
        validator: validator,
        extraFields: extraFields,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<TextVerificationDialog> createState() => _TextVerificationDialogState();
}

class _TextVerificationDialogState extends State<TextVerificationDialog> {
  final _controller = TextEditingController();
  final Map<String, TextEditingController> _extraControllers = {};
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final field in widget.extraFields) {
      _extraControllers[field.key] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _extraControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    final validationError = widget.validator?.call(value);
    if (validationError != null) {
      setState(() => _error = validationError);
      return;
    }
    for (final field in widget.extraFields) {
      final extraValue = _extraControllers[field.key]!.text.trim();
      final extraError = field.validator?.call(extraValue);
      if (extraError != null) {
        setState(() => _error = extraError);
        return;
      }
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final extra = {
        for (final field in widget.extraFields) field.key: _extraControllers[field.key]!.text.trim(),
      };
      await widget.onSubmit(value, extra);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not verify this right now. Please check the details and try again.');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: widget.keyboardType,
            maxLength: widget.maxLength,
            decoration: InputDecoration(hintText: widget.hint, counterText: ''),
          ),
          for (final field in widget.extraFields) ...[
            const SizedBox(height: 10),
            Text(field.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: _extraControllers[field.key],
              keyboardType: field.keyboardType,
              decoration: InputDecoration(hintText: field.hint),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Submit'),
        ),
      ],
    );
  }
}
