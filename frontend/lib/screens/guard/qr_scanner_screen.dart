// qr_scanner_screen.dart — S22: QR code scanner for guard entry/exit scanning
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../providers/guard_provider.dart';

/// S22 — QR Scanner screen.
///
/// Full-screen camera feed with:
/// - Dark scrim overlay with transparent cutout square
/// - Animated pulsing corner brackets
/// - Entry/Exit toggle pill at the top
/// - Instruction text at the bottom
///
/// Scans once per session — [_hasScanned] prevents duplicate processing.
/// On detect → calls [GuardProvider.processScan] → navigates to /guard/result.
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with SingleTickerProviderStateMixin {

  late final MobileScannerController _scannerController;
  late final AnimationController     _bracketAnimController;
  late final TextEditingController   _manualController;
  bool _hasScanned   = false;
  bool _isEntryMode  = true;

  static const double _scanSize = 260.0;

  // ── Lifecycle ─────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing:         CameraFacing.back,
    );
    _bracketAnimController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _manualController = TextEditingController();
    _isEntryMode = context.read<GuardProvider>().isEntryMode;
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _bracketAnimController.dispose();
    _manualController.dispose();
    super.dispose();
  }

  // ── Scan handler ─────────────────────────────────────────────────────────────

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() => _hasScanned = true);
    _scannerController.stop();

    final qrData = barcode!.rawValue!;
    await context.read<GuardProvider>().processScan(qrData);

    if (mounted) context.go('/guard/result');
  }

  // ── Toggle helper ─────────────────────────────────────────────────────────────

  Future<void> _onManualSubmit() async {
    final qrData = _manualController.text.trim();
    if (qrData.isEmpty || _hasScanned) return;

    setState(() => _hasScanned = true);
    _scannerController.stop();

    await context.read<GuardProvider>().processScan(qrData);
    if (mounted) context.go('/guard/result');
  }

  void _setMode(bool isEntry) {
    if (_isEntryMode == isEntry) return;
    setState(() => _isEntryMode = isEntry);
    context.read<GuardProvider>().setEntryMode(isEntry);
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Layer 1 — Camera feed (full screen)
          MobileScanner(
            controller: _scannerController,
            onDetect:   _onDetect,
          ),

          // Layer 2 — Dark scrim with cutout
          CustomPaint(
            size: Size.infinite,
            painter: _ScanOverlayPainter(scanSize: _scanSize),
          ),

          // Layer 3 — Animated corner brackets
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bracketAnimController,
              builder: (_, _) => Opacity(
                opacity: 0.5 + (_bracketAnimController.value * 0.5),
                child: CustomPaint(
                  painter: _CornerBracketsPainter(
                    color:  AppColors.warning,
                    size:   _scanSize,
                  ),
                ),
              ),
            ),
          ),

          // Layer 4 — Top UI (back button + toggle)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical:   16,
                ),
                child: Column(
                  children: [
                    // Back button row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.go('/guard/home'),
                          child: const Icon(
                            LucideIcons.arrowLeft,
                            size:  24,
                            color: Colors.white,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Scan QR Code',
                            style: TextStyle(
                              color:      Colors.white,
                              fontSize:   20,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 24),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Entry/Exit toggle pill
                    Center(
                      child: Container(
                        padding:    const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color:        Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildToggleSegment('Entry', _isEntryMode,  () => _setMode(true)),
                            _buildToggleSegment('Exit',  !_isEntryMode, () => _setMode(false)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Layer 5 — Bottom: manual entry + instruction text
          Positioned(
            bottom: 0,
            left:   0,
            right:  0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20, 0, 20,
                  MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Manual QR entry field
                    Container(
                      decoration: BoxDecoration(
                        color:        Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller:    _manualController,
                              style:         const TextStyle(
                                color:       Colors.white,
                                fontSize:    14,
                                fontWeight:  FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                              decoration: InputDecoration(
                                hintText:       'Enter QR code manually…',
                                hintStyle:      TextStyle(
                                  color:   Colors.white.withValues(alpha: 0.4),
                                  fontSize: 13,
                                ),
                                border:         InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical:   14,
                                ),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted:    (_) => _onManualSubmit(),
                            ),
                          ),
                          GestureDetector(
                            onTap: _onManualSubmit,
                            child: Container(
                              margin:  const EdgeInsets.all(6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical:   10,
                              ),
                              decoration: BoxDecoration(
                                color:        AppColors.warning,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Validate',
                                style: TextStyle(
                                  color:      Colors.black,
                                  fontSize:   13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Instruction text
                    Text(
                      'Point camera at QR code',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEntryMode ? 'Entry Scan' : 'Exit Scan',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSegment(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color:        isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? AppColors.background : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Scan overlay — dark scrim with transparent square cutout
// ─────────────────────────────────────────────────────────────────────────────

class _ScanOverlayPainter extends CustomPainter {
  final double scanSize;
  const _ScanOverlayPainter({required this.scanSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint  = Paint()..color = Colors.black.withValues(alpha: 0.8);
    final center = Offset(size.width / 2, size.height / 2);
    final scanRect = Rect.fromCenter(
      center: center,
      width:  scanSize,
      height: scanSize,
    );

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ScanOverlayPainter old) => old.scanSize != scanSize;
}

// ─────────────────────────────────────────────────────────────────────────────
// Corner brackets painter
// ─────────────────────────────────────────────────────────────────────────────

class _CornerBracketsPainter extends CustomPainter {
  final Color  color;
  final double size;

  const _CornerBracketsPainter({
    required this.color,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    const double strokeWidth   = 3;
    const double bracketLength = 24;

    final paint = Paint()
      ..color      = color
      ..strokeWidth = strokeWidth
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round;

    final left   = (canvasSize.width  - size) / 2;
    final top    = (canvasSize.height - size) / 2;
    final right  = left + size;
    final bottom = top  + size;
    final bl     = bracketLength;

    // Top-left
    canvas.drawLine(Offset(left, top + bl), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top),      Offset(left + bl, top), paint);
    // Top-right
    canvas.drawLine(Offset(right - bl, top), Offset(right, top), paint);
    canvas.drawLine(Offset(right, top),      Offset(right, top + bl), paint);
    // Bottom-left
    canvas.drawLine(Offset(left, bottom - bl), Offset(left, bottom), paint);
    canvas.drawLine(Offset(left, bottom),      Offset(left + bl, bottom), paint);
    // Bottom-right
    canvas.drawLine(Offset(right - bl, bottom), Offset(right, bottom), paint);
    canvas.drawLine(Offset(right, bottom),      Offset(right, bottom - bl), paint);
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter old) => old.color != color;
}
