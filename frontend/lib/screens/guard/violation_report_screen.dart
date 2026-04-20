// violation_report_screen.dart — S26: Guard reports a parking violation by plate
// number. Shows a form then transitions in-place to a suspension result card.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/violation_result.dart';
import '../../providers/guard_provider.dart';

/// S26 — Violation Report screen.
///
/// Presents a two-state view:
/// - Form state: plate input, violation type selector, optional notes, submit.
/// - Result state: suspension details returned from [GuardProvider.lastViolationResult].
///
/// Both states live in the same route — no navigation occurs on submit.
class ViolationReportScreen extends StatefulWidget {
  const ViolationReportScreen({super.key});

  @override
  State<ViolationReportScreen> createState() => _ViolationReportScreenState();
}

class _ViolationReportScreenState extends State<ViolationReportScreen> {
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _notesController  = TextEditingController();

  String? _selectedType;
  bool    _submitted = false;

  @override
  void initState() {
    super.initState();
    _plateController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _plateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Violation types ───────────────────────────────────────────────────────

  static const _types = [
    _ViolationType(
      value:    'NO_RESERVATION',
      title:    'No Reservation',
      subtitle: 'Car parked without valid reservation',
      icon:     LucideIcons.xCircle,
    ),
    _ViolationType(
      value:    'WRONG_SPOT',
      title:    'Wrong Spot',
      subtitle: 'Car parked in a different spot than reserved',
      icon:     LucideIcons.mapPinOff,
    ),
    _ViolationType(
      value:    'UNAUTHORIZED',
      title:    'Unauthorized',
      subtitle: 'Vehicle not registered under any badge',
      icon:     LucideIcons.shieldOff,
    ),
    _ViolationType(
      value:    'IDLING',
      title:    'Idling',
      subtitle: 'Vehicle occupying spot without parking',
      icon:     LucideIcons.timer,
    ),
  ];

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _badgeName(String type) {
    switch (type) {
      case 'CARPOOL_2': return 'Carpool 2';
      case 'CARPOOL_3': return 'Carpool 3';
      case 'CARPOOL_4': return 'Carpool 4';
      case 'CARPOOL_5': return 'Carpool 5';
      default:          return 'Individual';
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $h:$m';
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    final plate = _plateController.text.trim().toUpperCase();
    if (plate.isEmpty || _selectedType == null) return;

    final provider = context.read<GuardProvider>();
    provider.clearOperationError();

    final result = await provider.reportViolation(
      plateNumber:   plate,
      violationType: _selectedType!,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (!mounted) return;
    if (result != null) setState(() => _submitted = true);
  }

  void _resetForm() {
    _plateController.clear();
    _notesController.clear();
    setState(() {
      _selectedType = null;
      _submitted    = false;
    });
    context.read<GuardProvider>().clearViolationResult();
    context.read<GuardProvider>().clearOperationError();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GuardProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation:       0,
        leading: _submitted
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(LucideIcons.arrowLeft,
                    color: AppColors.textSecondary),
                onPressed: () => context.pop(),
              ),
        title: Text('Report Violation', style: AppTypography.displaySmall),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: _submitted
          ? _buildResult(provider.lastViolationResult!)
          : _buildForm(provider),
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────

  Widget _buildForm(GuardProvider provider) {
    final bool canSubmit = _plateController.text.trim().isNotEmpty
        && _selectedType != null
        && !provider.isReportingViolation;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Plate input ──────────────────────────────────────────────────
          Text('License Plate',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller:         _plateController,
            textCapitalization: TextCapitalization.characters,
            style: GoogleFonts.jetBrainsMono(
              fontSize:      14,
              fontWeight:    FontWeight.w500,
              color:         AppColors.textPrimary,
              letterSpacing: 1.2,
            ),
            decoration: InputDecoration(
              hintText:   'e.g. ABC 1234',
              hintStyle:  AppTypography.bodyMedium,
              filled:     true,
              fillColor:  AppColors.surfaceLight,
              prefixIcon: const Icon(LucideIcons.car,
                  size: 20, color: AppColors.textTertiary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                borderSide: const BorderSide(color: AppColors.error, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),

          const SizedBox(height: 24),

          // ── Violation type ───────────────────────────────────────────────
          Text('Violation Type',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          ..._types.map((t) => _ViolationTypeCard(
                type:       t,
                isSelected: _selectedType == t.value,
                onTap:      () => setState(() => _selectedType = t.value),
              )),

          const SizedBox(height: 24),

          // ── Notes ────────────────────────────────────────────────────────
          Text('Notes (optional)',
              style: AppTypography.labelMedium
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines:   3,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText:  'Additional details about the violation...',
              hintStyle: AppTypography.bodyMedium,
              filled:    true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                borderSide: const BorderSide(
                    color: AppColors.error, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),

          const SizedBox(height: 32),

          // ── Submit button ────────────────────────────────────────────────
          SizedBox(
            width:  double.infinity,
            height: AppSpacing.buttonHeight,
            child: ElevatedButton(
              onPressed: canSubmit ? _handleSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:         AppColors.error,
                disabledBackgroundColor: AppColors.divider,
                foregroundColor:         AppColors.background,
                elevation:               0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
              child: provider.isReportingViolation
                  ? const SizedBox(
                      width:  20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Submit Violation Report',
                      style: AppTypography.labelLarge
                          .copyWith(color: AppColors.background),
                    ),
            ),
          ),

          // ── Operation error ──────────────────────────────────────────────
          if (provider.operationError != null) ...[
            const SizedBox(height: 12),
            _ErrorBox(message: provider.operationError!),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Result ────────────────────────────────────────────────────────────────

  Widget _buildResult(ViolationResult result) {
    final plural = result.suspensionDays == 1 ? '' : 's';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),

          // Icon
          Container(
            width:  80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.shieldAlert,
              size:  44,
              color: AppColors.error,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Violation Reported',
            style: AppTypography.displaySmall
                .copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Badge has been automatically suspended',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Result card
          Container(
            width:       double.infinity,
            padding:     const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color:        AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Column(
              children: [
                _ResultRow(
                  label: 'Badge ID',
                  value: '#${result.badgeId}',
                ),
                const Divider(height: 16, color: AppColors.divider),
                _ResultRow(
                  label: 'Badge Type',
                  value: _badgeName(result.badgeType),
                ),
                const Divider(height: 16, color: AppColors.divider),
                _ResultRow(
                  label: 'Suspension',
                  value: '${result.suspensionDays} day$plural',
                ),
                const Divider(height: 16, color: AppColors.divider),
                _ResultRow(
                  label: 'Suspended Until',
                  value: _formatDate(result.suspendedUntil),
                ),
                const Divider(height: 16, color: AppColors.divider),
                _ResultRow(
                  label: 'Affected Students',
                  value: result.affectedStudents.join(', '),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Suspension pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:        AppColors.error.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Suspended for ${result.suspensionDays} day$plural',
              style:
                  AppTypography.labelMedium.copyWith(color: AppColors.error),
            ),
          ),

          const SizedBox(height: 32),

          // Report another
          SizedBox(
            width:  double.infinity,
            height: AppSpacing.buttonHeight,
            child: ElevatedButton(
              onPressed: _resetForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.background,
                elevation:       0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSpacing.buttonRadius),
                ),
              ),
              child: Text(
                'Report Another Violation',
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.background),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Back to dashboard
          SizedBox(
            width:  double.infinity,
            height: AppSpacing.buttonHeight,
            child: TextButton(
              onPressed: () => context.go('/guard/home'),
              child: Text(
                'Back to Dashboard',
                style: AppTypography.labelLarge
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Violation type card
// ─────────────────────────────────────────────────────────────────────────────

class _ViolationType {
  final String   value;
  final String   title;
  final String   subtitle;
  final IconData icon;
  const _ViolationType({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _ViolationTypeCard extends StatelessWidget {
  final _ViolationType type;
  final bool           isSelected;
  final VoidCallback   onTap;

  const _ViolationTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.error.withValues(alpha: 0.10)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.error : AppColors.divider,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              type.icon,
              size:  22,
              color: isSelected ? AppColors.error : AppColors.textTertiary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.title,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(type.subtitle, style: AppTypography.bodySmall),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(LucideIcons.checkCircle2,
                  size: 18, color: AppColors.error),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result info row
// ─────────────────────────────────────────────────────────────────────────────

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared error box
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadiusSmall),
        border:       Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle,
              size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
