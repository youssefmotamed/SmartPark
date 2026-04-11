// app_typography.dart — Typography system using Outfit + Plus Jakarta Sans + JetBrains Mono
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Centralised text style definitions.
///
/// - **Display**: Outfit — headings, large numbers, screen titles.
/// - **Body / Labels**: Plus Jakarta Sans — descriptions, list items, navigation.
/// - **Mono**: JetBrains Mono — plate numbers, countdown timers, QR payloads.
class AppTypography {
  const AppTypography._();

  // ── Display — Outfit ────────────────────────────────────────────────────────

  /// Screen-level heading — 32 px bold.
  static TextStyle get displayLarge => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.5,
      );

  /// Section heading — 24 px semi-bold.
  static TextStyle get displayMedium => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        letterSpacing: -0.3,
      );

  /// Card title / dialog heading — 20 px semi-bold.
  static TextStyle get displaySmall => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  // ── Body — Plus Jakarta Sans ────────────────────────────────────────────────

  /// Default body copy — 16 px regular, 1.5 line height.
  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
      );

  /// Secondary body / description — 14 px regular, textSecondary.
  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.4,
      );

  /// Caption / supporting detail — 12 px regular, textTertiary.
  static TextStyle get bodySmall => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
      );

  // ── Labels — Plus Jakarta Sans ───────────────────────────────────────────────

  /// Button text / prominent label — 16 px semi-bold.
  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Tab / badge label — 14 px semi-bold.
  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  /// Small tag / navigation label — 12 px medium, textSecondary.
  static TextStyle get labelSmall => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  // ── Mono — JetBrains Mono ───────────────────────────────────────────────────

  /// Inline monospace — plate numbers, short codes — 14 px.
  static TextStyle get mono => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        letterSpacing: 1.2,
      );

  /// Large monospace — countdown timer, QR reservation ID — 28 px.
  static TextStyle get monoLarge => GoogleFonts.jetBrainsMono(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
        letterSpacing: 2.0,
      );
}
