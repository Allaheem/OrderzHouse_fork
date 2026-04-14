import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/config/app_config.dart';
import '../widgets/admin_webview_body.dart';

/// Opens the admin SPA inside the app (same URLs as the web dashboard).
class AdminWebViewParams {
  const AdminWebViewParams({
    required this.webPath,
    required this.title,
  });

  /// Path from site root, e.g. `/admin/finance/plans`.
  final String webPath;
  final String title;
}

class AdminWebViewScreen extends StatefulWidget {
  const AdminWebViewScreen({super.key, required this.params});

  final AdminWebViewParams params;

  @override
  State<AdminWebViewScreen> createState() => _AdminWebViewScreenState();
}

class _AdminWebViewScreenState extends State<AdminWebViewScreen> {
  WebViewController? _controller;

  Uri get _initialUri {
    final origin = AppConfig.adminWebOrigin;
    final path = widget.params.webPath.startsWith('/')
        ? widget.params.webPath
        : '/${widget.params.webPath}';
    return Uri.parse('$origin$path');
  }

  void _handleBack() {
    final c = _controller;
    if (c == null) {
      if (mounted) context.pop();
      return;
    }
    c.canGoBack().then((can) {
      if (!mounted) return;
      if (can) {
        c.goBack();
      } else {
        context.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.params.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _handleBack,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _controller?.reload(),
            ),
          ],
        ),
        body: AdminWebViewBody(
          initialUri: _initialUri,
          onControllerCreated: (c) => _controller = c,
        ),
      ),
    );
  }
}
