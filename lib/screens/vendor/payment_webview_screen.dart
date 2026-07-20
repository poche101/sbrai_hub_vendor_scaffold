import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Opens a hosted checkout page (Paystack storefront or Espees portal)
/// and pops back with the reference once a callback/redirect URL is hit.
///
/// [callbackUrlContains] is a substring your backend's redirect URL is
/// guaranteed to contain (e.g. "sbraisolutions.com/payments/callback")
/// — adjust this to match whatever redirect_url your backend configures
/// for the Paystack/Espees transaction.
class PaymentWebViewScreen extends StatefulWidget {
  final String checkoutUrl;
  final String title;
  final String callbackUrlContains;

  const PaymentWebViewScreen({
    super.key,
    required this.checkoutUrl,
    this.title = 'Complete Payment',
    this.callbackUrlContains = '/payments/callback',
  });

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (url.contains(widget.callbackUrlContains)) {
              final uri = Uri.tryParse(url);
              final reference = uri?.queryParameters['reference'] ?? uri?.queryParameters['trxref'];
              Navigator.of(context).pop(reference ?? true);
              return;
            }
            setState(() => _loading = true);
          },
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
