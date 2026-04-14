import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

/// Same admin SPA as the website, embedded for mobile/iPad.
class AdminWebViewBody extends StatefulWidget {
  const AdminWebViewBody({
    super.key,
    required this.initialUri,
    this.onControllerCreated,
  });

  final Uri initialUri;
  final void Function(WebViewController controller)? onControllerCreated;

  @override
  State<AdminWebViewBody> createState() => _AdminWebViewBodyState();
}

/// Mobile Safari–like UA so fewer sites treat the session as a “blocked WebView”.
const String kAdminWebViewUserAgent =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 17_4 like Mac OS X) AppleWebKit/605.1.15 '
    '(KHTML, like Gecko) Version/17.4 Mobile/15E148 Safari/604.1';

class _AdminWebViewBodyState extends State<AdminWebViewBody> {
  late final WebViewController _controller;
  bool _loading = true;
  int _progress = 0;

  void _wireDelegate() {
    _controller.setNavigationDelegate(
      NavigationDelegate(
        onProgress: (p) {
          if (!mounted) return;
          setState(() {
            _progress = p;
            _loading = p < 100;
          });
        },
        onPageStarted: (_) {
          if (mounted) setState(() => _loading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _loading = false);
        },
        onWebResourceError: (err) {
          if (!mounted) return;
          setState(() => _loading = false);
          final msg = AppLocalizations.of(context)?.adminWebLaunchFailed;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                msg != null && err.description.isNotEmpty
                    ? '$msg: ${err.description}'
                    : (msg ?? err.description),
              ),
              backgroundColor: Colors.red,
            ),
          );
        },
      ),
    );
  }

  Future<void> _primeAndLoad(Uri uri) async {
    try {
      await _controller.setUserAgent(kAdminWebViewUserAgent);
    } catch (_) {}
    if (!mounted) return;
    widget.onControllerCreated?.call(_controller);
    await _controller.loadRequest(uri);
  }

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white);
    _wireDelegate();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _primeAndLoad(widget.initialUri);
    });
  }

  @override
  void didUpdateWidget(covariant AdminWebViewBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialUri != widget.initialUri) {
      setState(() => _loading = true);
      _controller.loadRequest(widget.initialUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_loading && _progress > 0 && _progress < 100)
          LinearProgressIndicator(
            value: _progress / 100.0,
            minHeight: 2,
            color: AppColors.gradientStart,
            backgroundColor: Colors.grey.shade200,
          )
        else if (_loading)
          const LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.gradientStart,
          ),
        Expanded(
          child: WebViewWidget(controller: _controller),
        ),
      ],
    );
  }
}
