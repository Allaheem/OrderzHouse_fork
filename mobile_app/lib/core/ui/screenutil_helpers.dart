// ??? ????????
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_spacing.dart';

/// Responsive size helpers. Use for widths and horizontal spacing.
/// Values scale from design size (390x844). Use getters (not const) after ScreenUtilInit.
class AppSize {
  AppSize._();

  static double get s4 => 4.w;
  static double get s6 => 6.w;
  static double get s8 => 8.w;
  static double get s10 => 10.w;
  static double get s12 => 12.w;
  static double get s16 => 16.w;
  static double get s18 => 18.w;
  static double get s20 => 20.w;
  static double get s24 => 24.w;
  static double get s28 => 28.w;
  static double get s32 => 32.w;
  static double get s40 => 40.w;
  static double get s48 => 48.w;
  static double get s56 => 56.w;
  static double get s64 => 64.w;
}

/// Vertical spacing / heights. Use for SizedBox(height: ...) and vertical padding.
class AppSizeH {
  AppSizeH._();

  static double get h4 => 4.h;
  static double get h6 => 6.h;
  static double get h8 => 8.h;
  static double get h10 => 10.h;
  static double get h12 => 12.h;
  static double get h16 => 16.h;
  static double get h18 => 18.h;
  static double get h20 => 20.h;
  static double get h24 => 24.h;
  static double get h28 => 28.h;
  static double get h32 => 32.h;
  static double get h40 => 40.h;
  static double get h48 => 48.h;
  static double get h56 => 56.h;
  static double get h64 => 64.h;
}

/// Border radius. Use for BorderRadius.circular(...).
class AppRadius {
  AppRadius._();

  static double get r4 => 4.r;
  static double get r8 => 8.r;
  static double get r10 => 10.r;
  static double get r12 => 12.r;
  static double get r16 => 16.r;
  static double get r20 => 20.r;
  static double get r24 => 24.r;
  static double get r30 => 30.r;
}

/// Font sizes. Use in TextStyle(fontSize: AppFont.f14).
class AppFont {
  AppFont._();

  static double get f10 => 10.sp;
  static double get f12 => 12.sp;
  static double get f14 => 14.sp;
  static double get f16 => 16.sp;
  static double get f18 => 18.sp;
  static double get f20 => 20.sp;
  static double get f22 => 22.sp;
  static double get f24 => 24.sp;
  static double get f28 => 28.sp;
  static double get f32 => 32.sp;
}

/// Fluid layout from the current window.
///
/// **When does the app “know” the screen size?**  
/// Flutter only has guaranteed [MediaQuery] / layout constraints **after the first frame**
/// (when the view is attached). You cannot lay out pixels “before” `runApp` in a meaningful
/// way; instead use [ScreenUtilInit] (design baseline + scaling) and [AppContentLayout] /
/// [LayoutBuilder] / [MediaQuery.sizeOf] in `build` so every route recomputes when the window
/// resizes (rotation, split view, Stage Manager).
abstract final class AppContentLayout {
  AppContentLayout._();

  /// 320 … 900 shortest-side → 0 … 1 (phones → large tablets / landscape).
  static double _windowT(BuildContext context) {
    final s = MediaQuery.sizeOf(context).shortestSide;
    return ((s - 320.0) / 580.0).clamp(0.0, 1.0);
  }

  /// Max width for centered shells (`Center` + `ConstrainedBox`).
  ///
  /// On **tablet-class** windows (`shortestSide >= 600`, e.g. iPad) returns **full logical
  /// width** so all screens using this API go edge-to-edge (minus your own horizontal padding).
  /// On phones keeps a readable capped column.
  static double contentMaxWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (useFullWidthBody(context)) {
      return w;
    }
    final s = MediaQuery.sizeOf(context).shortestSide;
    final t = ((s - 360.0) / 520.0).clamp(0.0, 1.0);
    final fraction = lerpDouble(0.91, 0.96, t)!;
    final maxCap = lerpDouble(840.0, 1024.0, t)!;
    return (w * fraction).clamp(300.0, maxCap);
  }

  /// Tablet / large window: full-bleed body (see [contentMaxWidth]).
  static bool useFullWidthBody(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= 600;
  }

  /// Horizontal inset for content on full-bleed tablets (comfortable side margins).
  static double fullBleedHorizontalPadding(BuildContext context) {
    final s = MediaQuery.sizeOf(context).shortestSide;
    return lerpDouble(20.0, 40.0, ((s - 520) / 380).clamp(0.0, 1.0))!;
  }

  /// Use for `SingleChildScrollView` / section padding: matches tablet full-bleed insets.
  static double bodyHorizontalPadding(BuildContext context) {
    return useFullWidthBody(context)
        ? fullBleedHorizontalPadding(context)
        : AppSpacing.lg;
  }

  /// “My Projects” / similar grids: more columns on wide layouts.
  static int myProjectsCrossAxisCount(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1200) return 4;
    if (w >= 760) return 3;
    return 2;
  }

  /// Grid cell aspect (width / height). [targetH] must cover [FreelancerProjectCard] / [ClientProjectCard]
  /// (image + padding + 2-line title + 4-line description + status chip); otherwise cells clip.
  static double myProjectsGridChildAspectRatio(
    BuildContext context,
    int crossAxisCount,
  ) {
    final w = MediaQuery.sizeOf(context).width;
    final horizontalPadding =
        AppSpacing.lg * 2 + AppSpacing.md * (crossAxisCount - 1);
    final cellW = (w - horizontalPadding) / crossAxisCount;
    const imageH = 120.0;
    // ~22 padding + ~34 title + 6 + ~66 description + 10 + ~24 chip; Arabic / metrics need slack.
    const bodyBase = 162.0;
    // Subpixel / strut / locale line metrics can exceed estimates by a few px (e.g. RTL titles).
    const layoutSlackPx = 10.0;
    final textScale =
        MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.45);
    final targetH = imageH + bodyBase * textScale + layoutSlackPx;
    final ratio = cellW / targetH;
    // Do not raise ratio too much on narrow cells (would shrink height below [targetH]).
    return ratio.clamp(0.52, 1.22);
  }

  /// Horizontal project strips on home: scales with window height.
  static double homeHorizontalRailHeight(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final t = _windowT(context);
    final base = h * lerpDouble(0.24, 0.29, t)!;
    return base.clamp(196.0, 312.0);
  }

  /// Project cards in horizontal lists: scales with shortest side (one hand / tablet).
  static double homeProjectCardWidth(BuildContext context) {
    final s = MediaQuery.sizeOf(context).shortestSide;
    return (s * lerpDouble(0.70, 0.76, _windowT(context))!).clamp(232.0, 384.0);
  }

  /// Bottom nav bar content row height (not including system home indicator).
  static double bottomNavBarHeight(BuildContext context) {
    return lerpDouble(64, 82, _windowT(context))!;
  }

  static double bottomNavIconSize(BuildContext context) {
    return lerpDouble(26, 32, _windowT(context))!;
  }

  static double bottomNavLabelFontSize(BuildContext context) {
    return lerpDouble(11.5, 13.5, _windowT(context))!;
  }

  /// Quick action chip column width under the home hero.
  static double quickActionItemWidth(BuildContext context) {
    return lerpDouble(68, 92, _windowT(context))!;
  }
}
