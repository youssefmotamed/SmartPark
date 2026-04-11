// app_spacing.dart — Spacing and layout constants for SmartPark
/// All spacing, radius, and dimension tokens.
///
/// Use these everywhere instead of magic numbers so changes propagate globally.
class AppSpacing {
  const AppSpacing._();

  // ── Base scale ───────────────────────────────────────────────────────────────
  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 16.0;
  static const double lg  = 24.0;
  static const double xl  = 32.0;
  static const double xxl = 48.0;

  // ── Screen padding ────────────────────────────────────────────────────────
  /// Horizontal screen edge padding.
  static const double screenH = 20.0;

  /// Vertical screen top/bottom padding.
  static const double screenV = 16.0;

  // ── Cards ────────────────────────────────────────────────────────────────────
  static const double cardPadding     = 16.0;
  static const double cardRadius      = 16.0;
  static const double cardRadiusSmall = 12.0;

  // ── Buttons ──────────────────────────────────────────────────────────────────
  static const double buttonHeight      = 52.0;
  static const double buttonRadius      = 14.0;
  static const double buttonRadiusSmall = 10.0;

  // ── Input fields ─────────────────────────────────────────────────────────────
  static const double inputHeight      = 52.0;
  static const double inputRadius      = 14.0;
  static const double inputBorderWidth = 1.5;

  // ── Bottom sheet ─────────────────────────────────────────────────────────────
  static const double bottomSheetRadius = 24.0;

  // ── Badge / pill ─────────────────────────────────────────────────────────────
  static const double badgeRadius = 20.0;
  static const double badgeHeight = 28.0;

  // ── Parking spot (map painter) ────────────────────────────────────────────
  static const double spotWidth  = 56.0;
  static const double spotHeight = 40.0;
  static const double spotRadius = 8.0;
}
