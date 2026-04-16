import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum PayPalApprovalResult {
  approved,
  cancelled,
  failed,
}

class PayPalApprovalWebViewScreen extends StatefulWidget {
  const PayPalApprovalWebViewScreen({
    super.key,
    required this.approvalUrl,
    required this.allowedReturnHosts,
  });

  final Uri approvalUrl;
  final Set<String> allowedReturnHosts;

  @override
  State<PayPalApprovalWebViewScreen> createState() =>
      _PayPalApprovalWebViewScreenState();
}

class _PayPalApprovalWebViewScreenState extends State<PayPalApprovalWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  int _progress = 0;

  NavigationDecision _handleNav(NavigationRequest req) {
    final uri = Uri.tryParse(req.url);
    if (uri != null) {
      final host = uri.host.toLowerCase();
      final isTrustedReturnHost = widget.allowedReturnHosts.contains(host);
      final isHttps = uri.scheme.toLowerCase() == 'https';
      final path = uri.path.toLowerCase();
      if (isHttps && isTrustedReturnHost && path.contains('/payment/paypal-return')) {
        Navigator.of(context).pop(PayPalApprovalResult.approved);
        return NavigationDecision.prevent;
      }
      if (isHttps && isTrustedReturnHost && path.contains('/payment/paypal-cancel')) {
        Navigator.of(context).pop(PayPalApprovalResult.cancelled);
        return NavigationDecision.prevent;
      }
    }
    return NavigationDecision.navigate;
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _handleNav,
          onProgress: (p) {
            if (!mounted) return;
            setState(() {
              _progress = p;
              _loading = p < 100;
            });
          },
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (!mounted) return;
            setState(() => _loading = false);
          },
          onWebResourceError: (_) {
            if (!mounted) return;
            Navigator.of(context).pop(PayPalApprovalResult.failed);
          },
        ),
      )
      ..loadRequest(widget.approvalUrl);
  }

  Future<void> _handleBack() async {
    final canGoBack = await _controller.canGoBack();
    if (!mounted) return;
    if (canGoBack) {
      await _controller.goBack();
      return;
    }
    Navigator.of(context).pop(PayPalApprovalResult.cancelled);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('PayPal Checkout'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _handleBack,
          ),
          actions: [
            IconButton(
              onPressed: () => _controller.reload(),
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_loading && _progress > 0 && _progress < 100)
              LinearProgressIndicator(value: _progress / 100.0, minHeight: 2)
            else if (_loading)
              const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}
