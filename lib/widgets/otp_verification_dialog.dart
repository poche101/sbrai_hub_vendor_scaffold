import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/kyc_status.dart';

/// A proper two-step OTP verification dialog: shows the user's actual
/// email/phone (read-only, pulled from their account — they never have
/// to type it), a "Send Code" step, then a 6-digit code entry step with
/// a resend option. Returns the updated [KycStatus] on success, or null
/// if the user cancels.
class OtpVerificationDialog extends StatefulWidget {
  final String title;
  final String target; // the actual email or phone number being verified
  final String targetLabel; // "email" or "phone number", for copy
  final Future<void> Function() onSendCode;
  final Future<KycStatus> Function(String otp) onVerify;

  const OtpVerificationDialog({
    super.key,
    required this.title,
    required this.target,
    required this.targetLabel,
    required this.onSendCode,
    required this.onVerify,
  });

  static Future<KycStatus?> show(
    BuildContext context, {
    required String title,
    required String target,
    required String targetLabel,
    required Future<void> Function() onSendCode,
    required Future<KycStatus> Function(String otp) onVerify,
  }) {
    return showDialog<KycStatus>(
      context: context,
      builder: (context) => OtpVerificationDialog(
        title: title,
        target: target,
        targetLabel: targetLabel,
        onSendCode: onSendCode,
        onVerify: onVerify,
      ),
    );
  }

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final _otpController = TextEditingController();
  bool _codeSent = false;
  bool _isSending = false;
  bool _isVerifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sendCode();
  }

  Future<void> _sendCode() async {
    setState(() {
      _isSending = true;
      _error = null;
    });
    try {
      await widget.onSendCode();
      if (!mounted) return;
      setState(() => _codeSent = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not send the code. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _verify() async {
    final code = _otpController.text.trim();
    if (code.length < 4) {
      setState(() => _error = 'Enter the code you received.');
      return;
    }
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    try {
      final status = await widget.onVerify(code);
      if (!mounted) return;
      Navigator.pop(context, status);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'That code looks incorrect or has expired. Please try again.');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF6F7F9), borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(widget.targetLabel == 'email' ? Icons.mail_outline : Icons.phone_outlined, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.target, style: const TextStyle(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_isSending && !_codeSent)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_codeSent) ...[
            Text('Enter the code we sent to your ${widget.targetLabel}.', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(counterText: '', hintText: '••••••'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isSending ? null : _sendCode,
                child: Text(_isSending ? 'Sending…' : 'Resend code'),
              ),
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
          onPressed: (!_codeSent || _isVerifying) ? null : _verify,
          child: _isVerifying
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Verify'),
        ),
      ],
    );
  }
}
