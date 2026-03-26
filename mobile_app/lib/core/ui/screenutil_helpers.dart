// ??? ????????
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
