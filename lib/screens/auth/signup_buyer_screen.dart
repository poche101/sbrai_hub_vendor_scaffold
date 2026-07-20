import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_messenger.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/password_field.dart';
import '../../widgets/social_login_buttons.dart';

class SignupBuyerScreen extends StatefulWidget {
  const SignupBuyerScreen({super.key});

  @override
  State<SignupBuyerScreen> createState() => _SignupBuyerScreenState();
}

class _SignupBuyerScreenState extends State<SignupBuyerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _termsAccepted = false;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Sign Up as Buyer',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Create your account to start shopping',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                SocialLoginButtons(
                  isLoading: auth.isLoading,
                  onGoogle: () async {
                    if (!_ensureTerms()) return;
                    await auth.continueWithGoogle(role: 'buyer', termsAccepted: _termsAccepted);
                    _afterAuth(auth);
                  },
                  onFacebook: () async {
                    if (!_ensureTerms()) return;
                    await auth.continueWithFacebook(role: 'buyer', termsAccepted: _termsAccepted);
                    _afterAuth(auth);
                  },
                ),
                AppTextField(controller: _name, label: 'Full Name', hint: 'John Doe'),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _email,
                  label: 'Email Address',
                  hint: 'john@example.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _phone,
                  label: 'Phone Number',
                  hint: '08012345678',
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().length < 10) ? 'Enter a valid phone number' : null,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _address,
                  label: 'Address (Optional)',
                  hint: 'Your location',
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _password,
                  hint: 'Minimum 6 characters',
                  validator: (v) => (v == null || v.length < 6) ? 'Minimum 6 characters' : null,
                ),
                const SizedBox(height: 16),
                PasswordField(
                  controller: _confirm,
                  label: 'Confirm Password',
                  hint: 'Re-enter password',
                  textInputAction: TextInputAction.done,
                  validator: (v) => v != _password.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 8),
                _TermsRow(value: _termsAccepted, onChanged: (v) => setState(() => _termsAccepted = v)),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(auth.errorMessage!, style: const TextStyle(color: AppColors.danger)),
                ],
                const SizedBox(height: 20),
                AppButton(
                  label: 'Create Account',
                  isLoading: auth.isLoading,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    if (!_ensureTerms()) return;
                    await auth.registerBuyer(
                      fullName: _name.text.trim(),
                      email: _email.text.trim(),
                      phone: _phone.text.trim(),
                      address: _address.text.trim().isEmpty ? null : _address.text.trim(),
                      password: _password.text,
                      termsAccepted: _termsAccepted,
                    );
                    _afterAuth(auth);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
                    TextButton(onPressed: () => context.push('/login'), child: const Text('Sign In')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _ensureTerms() {
    if (_termsAccepted) return true;
    AppMessenger.showError('Please accept the Terms of Service and Privacy Policy to continue.');
    return false;
  }

  void _afterAuth(AuthProvider auth) {
    // No manual navigation — see login_screen.dart for why.
    if (auth.isLoggedIn) {
      AppMessenger.showSuccess('Account created successfully! Welcome to Sbrai Hub.');
    } else if (auth.errorMessage != null) {
      AppMessenger.showError(auth.errorMessage!);
    }
  }
}

class _TermsRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _TermsRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
        const Expanded(
          child: Text('I agree to the Terms of Service and Privacy Policy', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}
