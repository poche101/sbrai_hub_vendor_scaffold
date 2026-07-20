import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/app_messenger.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/password_field.dart';
import '../../widgets/social_login_buttons.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _termsAccepted = false;
  String _role = 'buyer'; // used for social login role selection

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final locale = context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(locale.t('signIn'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(locale.t('welcomeBack'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(locale.t('signInSubtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 28),
                SocialLoginButtons(
                  isLoading: auth.isLoading,
                  onGoogle: () async {
                    if (!_ensureTermsAccepted()) return;
                    await auth.continueWithGoogle(
                        role: _role, termsAccepted: _termsAccepted);
                    _handleResult(auth);
                  },
                  onFacebook: () async {
                    if (!_ensureTermsAccepted()) return;
                    await auth.continueWithFacebook(
                        role: _role, termsAccepted: _termsAccepted);
                    _handleResult(auth);
                  },
                ),
                AppTextField(
                  controller: _email,
                  label: locale.t('emailAddress'),
                  hint: 'john@example.com',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 16),
                PasswordField(
                    controller: _password,
                    label: locale.t('password'),
                    textInputAction: TextInputAction.done),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text(locale.t('forgotPassword')),
                  ),
                ),
                const SizedBox(height: 4),
                _TermsCheckbox(
                  value: _termsAccepted,
                  onChanged: (v) => setState(() => _termsAccepted = v),
                ),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(auth.errorMessage!,
                      style: const TextStyle(color: AppColors.danger)),
                ],
                const SizedBox(height: 20),
                AppButton(
                  label: locale.t('signIn'),
                  isLoading: auth.isLoading,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    if (!_ensureTermsAccepted()) return;
                    await auth.loginBuyerOrVendor(
                      email: _email.text.trim(),
                      password: _password.text,
                      termsAccepted: _termsAccepted,
                    );
                    _handleResult(auth);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${locale.t('noAccount')} '),
                    TextButton(
                        onPressed: () => context.go('/role-select'),
                        child: Text(locale.t('signUp'))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _ensureTermsAccepted() {
    if (_termsAccepted) return true;
    AppMessenger.showError(
        'Please accept the Terms of Service and Privacy Policy to continue.');
    return false;
  }

  void _handleResult(AuthProvider auth) {
    // No manual navigation here — the router's redirect callback moves
    // us to /home or /vendor/kyc automatically once auth.isLoggedIn flips
    // to true, avoiding a second navigation racing this one.
    if (auth.isLoggedIn) {
      final name = auth.currentUser?.fullName.split(' ').first ?? '';
      AppMessenger.showSuccess(
          name.isNotEmpty ? 'Welcome back, $name!' : 'Welcome back!');
    } else if (auth.errorMessage != null) {
      AppMessenger.showError(auth.errorMessage!);
    }
  }
}

class _TermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _TermsCheckbox({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Checkbox(value: value, onChanged: (v) => onChanged(v ?? false)),
        Expanded(
          child: Wrap(
            children: [
              const Text('I agree to the ', style: TextStyle(fontSize: 13)),
              GestureDetector(
                onTap: () {},
                child: const Text('Terms of Service',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
              const Text(' and ', style: TextStyle(fontSize: 13)),
              GestureDetector(
                onTap: () {},
                child: const Text('Privacy Policy',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
