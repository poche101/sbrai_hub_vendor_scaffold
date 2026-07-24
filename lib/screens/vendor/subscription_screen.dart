import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/api_config.dart';
import '../../core/config/platform_support.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/vendor_status_provider.dart';
import '../../services/subscription_service.dart';
import '../../widgets/app_button.dart';
import 'payment_webview_screen.dart';

enum _Method { paystack, espees }

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final _subscriptionService = SubscriptionService();
  _Method _method = _Method.paystack;
  bool _isProcessing = false;
  String? _error;

  Future<void> _pay() async {
    if (_method == _Method.espees) {
      await _payWithEspees();
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final init = await _subscriptionService.getPaystackCheckout();
      await _openCheckout(init.checkoutUrl, init.reference,
          verify: _subscriptionService.verifyPaystack);
    } catch (e) {
      setState(() => _error = 'Could not start payment. Please try again.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  /// Espees is a direct wallet debit (wallet ID + PIN), confirmed
  /// synchronously in the same request — there's no hosted checkout page
  /// to open, unlike Paystack.
  Future<void> _payWithEspees() async {
    final walletController = TextEditingController();
    final pinController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pay with Espees'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Wallet ID',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
                controller: walletController,
                decoration:
                    const InputDecoration(hintText: 'Your Espees wallet ID')),
            const SizedBox(height: 12),
            const Text('PIN',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                  hintText: '4-6 digit PIN', counterText: ''),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Pay')),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    if (walletController.text.trim().isEmpty ||
        pinController.text.trim().length < 4) {
      setState(() => _error = 'Enter a valid wallet ID and 4-6 digit PIN.');
      return;
    }

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      await _subscriptionService.payWithEspees(
        walletId: walletController.text.trim(),
        pin: pinController.text.trim(),
      );
      final vendorStatus = context.read<VendorStatusProvider>();
      await vendorStatus.refresh();
      if (!mounted) return;

      if (vendorStatus.subscription.isActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Subscription active! You can now post ads.'),
              backgroundColor: AppColors.success),
        );
        context.pop();
      } else {
        setState(
            () => _error = 'Payment could not be confirmed. Please try again.');
      }
    } catch (_) {
      setState(() => _error =
          'Espees payment failed. Please check your wallet ID and PIN and try again.');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _openCheckout(
    String? checkoutUrl,
    String? reference, {
    Future<dynamic> Function(String reference)? verify,
  }) async {
    if (checkoutUrl == null) {
      setState(() => _error =
          'Payment could not be initialized. Please try again shortly.');
      return;
    }

    dynamic result;
    if (PlatformSupport.supportsInAppWebView) {
      result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(
            checkoutUrl: checkoutUrl,
            title: _method == _Method.paystack
                ? 'Pay with Paystack'
                : 'Pay with Espees',
          ),
        ),
      );
    } else {
      // Windows: no in-app WebView support, so open the hosted checkout
      // in the system browser and let the user confirm once they return.
      await launchUrl(Uri.parse(checkoutUrl),
          mode: LaunchMode.externalApplication);
      if (!mounted) return;
      result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Complete payment in your browser'),
          content: const Text(
              'Once you\'ve finished paying, come back here and tap Confirm.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm')),
          ],
        ),
      );

      // There's no Paystack webhook route on the backend — verification
      // only happens when the app calls POST /subscriptions/paystack/verify
      // with a reference. The in-app WebView captures that reference
      // automatically from Paystack's redirect; the external-browser path
      // has no such hook, so ask for it directly or the subscription can
      // never be confirmed.
      if (result == true && mounted) {
        final refController = TextEditingController();
        result = await showDialog<String?>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm your payment'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter the transaction reference from your Paystack receipt email to confirm your subscription.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: refController,
                    decoration:
                        const InputDecoration(hintText: 'e.g. T123456789')),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(context, refController.text.trim()),
                child: const Text('Verify'),
              ),
            ],
          ),
        );
      } else {
        result = null;
      }
    }

    if (result == null || result == false || !mounted) return;

    try {
      if (verify != null) {
        final ref = (result is String) ? result : reference;
        if (ref != null) await verify(ref);
      }
      final vendorStatus = context.read<VendorStatusProvider>();
      await vendorStatus.refresh();
      if (!mounted) return;

      if (vendorStatus.subscription.isActive) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Subscription active! You can now post ads.'),
              backgroundColor: AppColors.success),
        );
        context.pop();
      } else {
        setState(() => _error =
            'Payment received but not yet confirmed. Please check back shortly.');
      }
    } catch (_) {
      setState(() => _error =
          'Could not confirm your payment. If you were charged, please contact support.');
    }
  }

  Future<void> _openEspeesSignup() async {
    await launchUrl(Uri.parse('https://espeesmax.online/login'),
        mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Subscription')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: AppColors.primaryLight,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.workspace_premium_outlined,
                        size: 40, color: AppColors.primary),
                    const SizedBox(height: 10),
                    const Text('Unlock Unlimited Ad Posting',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 6),
                    const Text(
                      'A one-time vendor subscription is required before you can post products, services, or property listings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Choose a Payment Method',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _MethodTile(
              title: 'Pay with Paystack',
              subtitle:
                  '₦${ApiConfig.subscriptionFeeNaira} — Card, bank transfer, or USSD',
              icon: Icons.credit_card,
              selected: _method == _Method.paystack,
              onTap: () => setState(() => _method = _Method.paystack),
            ),
            const SizedBox(height: 12),
            _MethodTile(
              title: 'Pay with Espees',
              subtitle: '${ApiConfig.subscriptionFeeEspees} Espees',
              imageAsset: 'assets/images/espees.png',
              selected: _method == _Method.espees,
              onTap: () => setState(() => _method = _Method.espees),
            ),
            if (_method == _Method.espees) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  onTap: _openEspeesSignup,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      "Don't have an Espees account? Create one",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  style: const TextStyle(color: AppColors.danger),
                  textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            AppButton(
              label: _method == _Method.paystack
                  ? 'Pay ₦${ApiConfig.subscriptionFeeNaira}'
                  : 'Pay ${ApiConfig.subscriptionFeeEspees} Espees',
              isLoading: _isProcessing,
              onPressed: _pay,
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData? icon;
  final String? imageAsset;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.title,
    required this.subtitle,
    this.icon,
    this.imageAsset,
    required this.selected,
    required this.onTap,
  }) : assert(icon != null || imageAsset != null,
            'Provide either icon or imageAsset');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
          color: selected ? AppColors.primaryLight : Colors.white,
        ),
        child: Row(
          children: [
            if (imageAsset != null)
              Image.asset(
                imageAsset!,
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.currency_exchange,
                    color:
                        selected ? AppColors.primary : AppColors.textSecondary),
              )
            else
              Icon(icon,
                  color:
                      selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Radio<bool>(
                value: true,
                groupValue: selected ? true : null,
                onChanged: (_) => onTap()),
          ],
        ),
      ),
    );
  }
}
