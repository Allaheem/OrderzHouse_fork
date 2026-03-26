// ??? ????????
import 'package:flutter/material.dart';
import 'top_glow_background.dart';

/// Reusable scaffold wrapper with white background and subtle top gradient glow
/// Uses TopGlowBackground for consistent styling across the app
class AppScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final bool showAppBar;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool extendBodyBehindAppBar;
  final bool useSafeArea;

  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.showAppBar = false,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.extendBodyBehindAppBar = true,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: showAppBar
          ? (appBar ??
                AppBar(
                  title: title != null ? Text(title!) : null,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                ))
          : null,
      body: TopGlowBackground(useSafeArea: useSafeArea, child: body),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
