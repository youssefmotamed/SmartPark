// violation_report_screen.dart — S26: Guard reports a parking violation
// Light gray background, white fields, radio-style violation cards, result state.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../models/violation_result.dart';
import '../../providers/guard_provider.dart';

class ViolationReportScreen extends StatefulWidget {
  const ViolationReportScreen({super.key});

  @override
  State<ViolationReportScreen> createState() => _ViolationReportScreenState();
}

class _ViolationReportScreenState extends State<ViolationReportScreen> {
  final _plateController = TextEditingController();
  final _notesController  = TextEditingController();
  String? _selectedType;
  bool    _submitted = false;

  static const _kPageBg   = Color(0xFFEEF1F7);
  static const _kCardText = Color(0xFF1A2035);
  static const _kCardSub  = Color(0xFF6B7280);
  static const _kLabel    = Color(0xFF374151);

  static const _types = [
    _VType('NO_RESERVATION',  'No Reservation',
        'Vehicle in spot without active reservation'),
    _VType('WRONG_SPOT',      'Wrong Spot',
        'Vehicle parked in a different spot than reserved'),
    _VType('UNAUTHORIZED',    'Unauthorized Vehicle',
        'Plate not registered to any active badge'),
    _VType('IDLING',          'Idling',
        'Vehicle blocking spot with engine running'),
  ];

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
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $h:$m';
  }

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
    setState(() { _selectedType = null; _submitted = false; });
    context.read<GuardProvider>()
      ..clearViolationResult()
      ..clearOperationError();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GuardProvider>();
    return Scaffold(
      backgroundColor: _kPageBg,
      body: _submitted
          ? _buildResult(provider.lastViolationResult!)
          : _buildForm(provider),
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────

  Widget _buildForm(GuardProvider provider) {
    final canSubmit = _plateController.text.trim().isNotEmpty
        && _selectedType != null
        && !provider.isReportingViolation;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── License plate ─────────────────────────────────────────────────
          _SectionLabel('LICENSE PLATE'),
          const SizedBox(height: 10),
          TextField(
            controller: _plateController,
            textCapitalization: TextCapitalization.characters,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 22, fontWeight: FontWeight.w700,
              color: _kCardText, letterSpacing: 3,
            ),
            decoration: InputDecoration(
              hintText: 'ABC 1234',
              hintStyle: GoogleFonts.jetBrainsMono(
                fontSize: 22, color: Colors.black26, letterSpacing: 3,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF374151), width: 2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Violation type ────────────────────────────────────────────────
          _SectionLabel('VIOLATION TYPE'),
          const SizedBox(height: 10),

          ..._types.map((t) => _ViolationCard(
            type: t,
            isSelected: _selectedType == t.value,
            onTap: () => setState(() => _selectedType = t.value),
          )),

          const SizedBox(height: 20),

          // ── Notes ─────────────────────────────────────────────────────────
          Row(
            children: [
              Text('NOTES', style: GoogleFonts.manrope(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: _kLabel, letterSpacing: 1.2,
              )),
              const SizedBox(width: 6),
              Text('(OPTIONAL)', style: GoogleFonts.manrope(
                fontSize: 11, color: _kCardSub, letterSpacing: 1.2,
              )),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            maxLines: 4,
            style: GoogleFonts.manrope(fontSize: 14, color: _kCardText),
            decoration: InputDecoration(
              hintText: 'Additional context or observations...',
              hintStyle: GoogleFonts.manrope(
                  fontSize: 14, color: Colors.black38),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF374151), width: 2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Submit button ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: canSubmit ? _handleSubmit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                disabledBackgroundColor: const Color(0xFFDDE2EE),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: provider.isReportingViolation
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : Text(
                      'Submit Violation Report',
                      style: GoogleFonts.manrope(
                        fontSize: 15, fontWeight: FontWeight.w700,
                        color: canSubmit
                            ? Colors.white
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
            ),
          ),

          if (provider.operationError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(LucideIcons.alertCircle,
                    size: 16, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(child: Text(provider.operationError!,
                    style: GoogleFonts.manrope(
                        color: AppColors.error, fontSize: 13))),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  // ── Result ────────────────────────────────────────────────────────────────

  Widget _buildResult(ViolationResult result) {
    final plural = result.suspensionDays == 1 ? '' : 's';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 32, 16, 32),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.shieldAlert,
                size: 40, color: AppColors.error),
          ),
          const SizedBox(height: 20),
          Text('Violation Reported',
              style: GoogleFonts.manrope(
                fontSize: 22, fontWeight: FontWeight.w800, color: _kCardText),
              textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('Badge has been automatically suspended',
              style: GoogleFonts.manrope(fontSize: 14, color: _kCardSub),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),

          // Result card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(8),
                  blurRadius: 8, offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _Row('Badge ID', '#${result.badgeId}'),
                const Divider(height: 20, color: Color(0xFFF0F0F0)),
                _Row('Badge Type', _badgeName(result.badgeType)),
                const Divider(height: 20, color: Color(0xFFF0F0F0)),
                _Row('Suspension', '${result.suspensionDays} day$plural'),
                const Divider(height: 20, color: Color(0xFFF0F0F0)),
                _Row('Suspended Until', _formatDate(result.suspendedUntil)),
                const Divider(height: 20, color: Color(0xFFF0F0F0)),
                _Row('Affected Students',
                    result.affectedStudents.join(', ')),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Suspended for ${result.suspensionDays} day$plural',
              style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.error),
            ),
          ),

          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _resetForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text('Report Another Violation',
                  style: GoogleFonts.manrope(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 52,
            child: TextButton(
              onPressed: () => context.go('/guard/home'),
              child: Text('Back to Dashboard',
                  style: GoogleFonts.manrope(
                      fontSize: 15, color: _kCardSub,
                      fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _VType {
  final String value, title, subtitle;
  const _VType(this.value, this.title, this.subtitle);
}

class _ViolationCard extends StatelessWidget {
  final _VType type;
  final bool   isSelected;
  final VoidCallback onTap;
  const _ViolationCard({
    required this.type, required this.isSelected, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.error : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(6),
              blurRadius: 6, offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Radio circle
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.error
                      : const Color(0xFFD1D5DB),
                  width: isSelected ? 6 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.title,
                      style: GoogleFonts.manrope(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A2035),
                      )),
                  const SizedBox(height: 2),
                  Text(type.subtitle,
                      style: GoogleFonts.manrope(
                          fontSize: 12, color: const Color(0xFF6B7280))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(LucideIcons.alertTriangle,
                size: 18,
                color: isSelected
                    ? AppColors.error.withAlpha(180)
                    : const Color(0xFFD1D5DB)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.manrope(
          fontSize: 11, fontWeight: FontWeight.w700,
          color: const Color(0xFF374151), letterSpacing: 1.2,
        ));
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.manrope(
            fontSize: 13, color: const Color(0xFF6B7280))),
        const SizedBox(width: 16),
        Flexible(
          child: Text(value,
              textAlign: TextAlign.right,
              style: GoogleFonts.manrope(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: const Color(0xFF1A2035),
              )),
        ),
      ],
    );
  }
}
