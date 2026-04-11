// colors.dart — Dark-mode-first color system for SmartPark
import 'package:flutter/material.dart';

/// All brand and semantic colors. Use these everywhere — never hardcode hex values.
class AppColors {
  const AppColors._();

  // ── Backgrounds ─────────────────────────────────────────────────────────────
  /// Deepest background — main scaffold color.
  static const Color background       = Color(0xFF0F1117);

  /// Default surface — cards, bottom sheets, modals.
  static const Color surface          = Color(0xFF1A1D27);

  /// Slightly elevated surface — list items, input fills.
  static const Color surfaceLight     = Color(0xFF242837);

  /// Highlighted surface — hover/selected states, alternate rows.
  static const Color surfaceHighlight = Color(0xFF2E3347);

  // ── Text ────────────────────────────────────────────────────────────────────
  /// Primary text — headings and body on dark surfaces.
  static const Color textPrimary      = Color(0xFFEEF0F6);

  /// Secondary text — labels, subtitles, descriptions.
  static const Color textSecondary    = Color(0xFF8B90A5);

  /// Tertiary text — hints, placeholders, disabled content.
  static const Color textTertiary     = Color(0xFF5A5F75);

  // ── Spot status ─────────────────────────────────────────────────────────────
  /// Spot is free to reserve.
  static const Color available        = Color(0xFF00E676);

  /// Spot is reserved but not yet entered.
  static const Color reserved         = Color(0xFFFFAB40);

  /// A car is physically present.
  static const Color occupied         = Color(0xFFFF5252);

  /// Spot is out of service.
  static const Color unavailable      = Color(0xFF4A4E5E);

  // ── Spot status glows (for map overlay effects) ──────────────────────────
  static const Color availableGlow    = Color(0x3300E676);
  static const Color reservedGlow     = Color(0x33FFAB40);
  static const Color occupiedGlow     = Color(0x33FF5252);

  // ── Brand / accent ──────────────────────────────────────────────────────────
  /// Primary interactive color — electric blue accent.
  static const Color primary          = Color(0xFF4FC3F7);

  /// Darker variant of primary — pressed states, gradients.
  static const Color primaryDark      = Color(0xFF0288D1);

  /// Primary glow — used for shadows and focus rings on the map.
  static const Color primaryGlow      = Color(0x334FC3F7);

  // ── Semantic aliases ─────────────────────────────────────────────────────
  /// Success state — same as [available].
  static const Color success          = Color(0xFF00E676);

  /// Warning state — same as [reserved].
  static const Color warning          = Color(0xFFFFAB40);

  /// Error / destructive state.
  static const Color error            = Color(0xFFFF5252);

  /// Informational state — same as [primary].
  static const Color info             = Color(0xFF4FC3F7);

  // ── Carpool badge tier colors ────────────────────────────────────────────
  static const Color carpool2         = Color(0xFF7C4DFF);
  static const Color carpool3         = Color(0xFF00BFA5);
  static const Color carpool4         = Color(0xFFFF6E40);
  static const Color carpool5         = Color(0xFFFFD740);
  static const Color individual       = Color(0xFF4FC3F7);

  // ── Misc ────────────────────────────────────────────────────────────────────
  /// Shimmer highlight — used in loading skeleton widgets.
  static const Color shimmer          = Color(0x0DFFFFFF);

  /// Divider / separator lines.
  static const Color divider          = Color(0xFF2A2E3D);

  /// Modal scrim — darkens background behind bottom sheets and dialogs.
  static const Color scrim            = Color(0xCC000000);
}
