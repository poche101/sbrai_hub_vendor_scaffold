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

class SignupVendorScreen extends StatefulWidget {
  const SignupVendorScreen({super.key});

  @override
  State<SignupVendorScreen> createState() => _SignupVendorScreenState();
}

class _SignupVendorScreenState extends State<SignupVendorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _businessName = TextEditingController();
  final _businessId = TextEditingController();
  final _businessAddress = TextEditingController();
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
                const Text('Sign Up as Vendor',
                    textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text('Create your business account to start selling',
                    textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                SocialLoginButtons(
                  isLoading: auth.isLoading,
                  onGoogle: () async {
                    if (!_ensureTerms()) return;
                    await auth.continueWithGoogle(role: 'vendor', termsAccepted: _termsAccepted);
                    _afterAuth(auth);
                  },
                  onFacebook: () async {
                    if (!_ensureTerms()) return;
                    await auth.continueWithFacebook(role: 'vendor', termsAccepted: _termsAccepted);
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
                AppTextField(controller: _businessName, label: 'Business Name', hint: 'ABC Building Supplies'),
                const SizedBox(height: 16),
                AppTextField(controller: _businessId, label: 'Business ID (Optional)', hint: 'CAC Registration Number'),
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Provide business ID to get verified badge', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
                const SizedBox(height: 16),
                AppTextField(controller: _businessAddress, label: 'Business Address', hint: 'Shop 5, Ikeja, Lagos'),
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
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFEFF3FF), borderRadius: BorderRadius.circular(10)),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.navy, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'After signup you\'ll need to complete KYC verification and a ₦25,000 (or 10 Espees) subscription before you can post ads.',
                          style: TextStyle(fontSize: 12, color: AppColors.navy),
                        ),
                      ),
                    ],
                  ),
                ),
                if (auth.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(auth.errorMessage!, style: const TextStyle(color: AppColors.danger)),
                ],
                const SizedBox(height: 20),
                AppButton(
                  label: 'Create Vendor Account',
                  color: AppColors.navy,
                  isLoading: auth.isLoading,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    if (!_ensureTerms()) return;
                    await auth.registerVendor(
                      fullName: _name.text.trim(),
                      email: _email.text.trim(),
                      phone: _phone.text.trim(),
                      businessName: _businessName.text.trim(),
                      businessId: _businessId.text.trim().isEmpty ? null : _businessId.text.trim(),
                      businessAddress: _businessAddress.text.trim(),
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
    // No manual navigation — see login_screen.dart for why. The router
    // sends vendors straight to /vendor/kyc automatically.
    if (auth.isLoggedIn) {
      AppMessenger.showSuccess('Vendor account created! Let\'s verify your identity.');
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
