// login_screen.dart — S02: Login screen — "THE GATE" aesthetic
// Industrial-bold split layout: near-black header with ghost "P" + diagonal
// stripe watermark; dark surface card rises from below. Bebas Neue × Manrope.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';

/// S02 — Login screen for all user roles.
///
/// Phase 0: catches [UnimplementedError] from [AuthProvider.login] and
/// mocks navigation to `/student/home` so the UI flow can be tested end-to-end.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ── Form state ─────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _buttonPressed = false;

  // ── Animation controllers ──────────────────────────────────────────────────

  /// Logo fade + white card slide (600 ms total).
  late final AnimationController _bgController;

  /// Staggered reveal of form elements inside the card (600 ms, starts after
  /// the card is on-screen).
  late final AnimationController _formController;

  /// Horizontal shake played when a login error surfaces (300 ms).
  late final AnimationController _shakeController;

  // bg group
  late final Animation<double> _logoFade;
  late final Animation<Offset> _cardSlide;

  // form group
  late final Animation<double> _cardHeaderFade;
  late final Animation<double> _emailFade;
  late final Animation<Offset> _emailSlide;
  late final Animation<double> _passwordFade;
  late final Animation<Offset> _passwordSlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;

  // shake
  late final Animation<double> _shakeOffset;

  @override
  void initState() {
    super.initState();

    // ── Background / card entrance ─────────────────────────────────────────
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    _logoFade = CurvedAnimation(
      parent: _bgController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeIn),
    );

    // White card slides up from fully off-screen (Offset(0,1) = 100% own height).
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bgController,
      curve: const Interval(0.0, 0.88, curve: Curves.easeOutQuart),
    ));

    // ── Form content stagger ───────────────────────────────────────────────
    // Controller starts 360 ms after _bgController — card is ~75 % in by then.
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    const c = Curves.easeOutCubic;
    const slideStart = Offset(0, 0.18);

    _cardHeaderFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.00, 0.50, curve: c),
      ),
    );

    _emailFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.12, 0.62, curve: c),
      ),
    );
    _emailSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.12, 0.62, curve: c),
      ),
    );

    _passwordFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.27, 0.77, curve: c),
      ),
    );
    _passwordSlide =
        Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.27, 0.77, curve: c),
      ),
    );

    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.42, 1.00, curve: c),
      ),
    );
    _buttonSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.42, 1.00, curve: c),
      ),
    );

    // ── Error shake ────────────────────────────────────────────────────────
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shakeOffset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -9.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -9.0, end: 9.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 9.0, end: -5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5.0, end: 5.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);

    // Kick off entrance sequence
    _bgController.forward();
    Future.delayed(
      const Duration(milliseconds: 360),
      () { if (mounted) _formController.forward(); },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _bgController.dispose();
    _formController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _handleLogin() async {
    context.read<AuthProvider>().clearError();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await context.read<AuthProvider>().login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    if (auth.error != null) {
      _shakeController.forward(from: 0);
      return;
    }

    switch (auth.role) {
      case 'GUARD':
        context.go('/guard/home');
      case 'ADMIN':
        context.go('/admin/home');
      default:
        context.go('/student/home');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      // Deep background fills any gap that shows behind the card during animation.
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // 1 — Diagonal stripe watermark across the whole screen.
          Positioned.fill(
            child: CustomPaint(painter: _DiagonalStripePainter()),
          ),

          // 2 — Giant ghost "P" — the one thing users remember.
          Positioned(
            right: -20,
            top: 20,
            child: FadeTransition(
              opacity: _logoFade,
              child: Text(
                'P',
                style: GoogleFonts.bebasNeue(
                  fontSize: 260,
                  color: Colors.white.withAlpha(12), // ≈ 5 %
                  height: 1,
                ),
              ),
            ),
          ),

          // 3 — Content column: logo zone (blue) + form card (white).
          Column(
            children: [
              // Blue zone — logo + tagline
              SafeArea(
                bottom: false,
                child: FadeTransition(
                  opacity: _logoFade,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 44, 28, 36),
                    child: _buildLogoArea(),
                  ),
                ),
              ),

              // White card — clips the slide-up so it never overlaps the logo.
              Expanded(
                child: ClipRect(
                  child: SlideTransition(
                    position: _cardSlide,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 36, 28, 48),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildCardHeader(),
                              const SizedBox(height: 32),
                              _buildEmailField(auth),
                              const SizedBox(height: 16),
                              _buildPasswordField(auth),
                              const SizedBox(height: 24),
                              _buildErrorCard(auth),
                              _buildLoginButton(auth),
                              const SizedBox(height: 30),
                              _buildRegisterLink(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section builders ───────────────────────────────────────────────────────

  /// Brand identity — all-caps Bebas Neue wordmark + amber tagline.
  Widget _buildLogoArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pill badge: "SMART PARKING SYSTEM"
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.reserved.withAlpha(38), // amber at ~15 %
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'SMART PARKING SYSTEM',
            style: GoogleFonts.manrope(
              fontSize: 10,
              color: AppColors.reserved,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Wordmark
        Text(
          'SMART\nPARK',
          style: GoogleFonts.bebasNeue(
            fontSize: 56,
            color: Colors.white,
            letterSpacing: 3,
            height: 0.95,
          ),
        ),
        const SizedBox(height: 10),

        // Decorative amber rule + tagline
        Row(
          children: [
            Container(
              width: 24,
              height: 2.5,
              decoration: BoxDecoration(
                color: AppColors.reserved,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Park smarter.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: Colors.white.withAlpha(178), // 70 %
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Card subtitle — "Welcome back / Sign in…"
  Widget _buildCardHeader() {
    return FadeTransition(
      opacity: _cardHeaderFade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back',
            style: GoogleFonts.manrope(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Sign in to continue',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// Email text field.
  Widget _buildEmailField(AuthProvider auth) {
    return FadeTransition(
      opacity: _emailFade,
      child: SlideTransition(
        position: _emailSlide,
        child: _InputField(
          controller: _emailController,
          enabled: !auth.isLoading,
          hint: 'Email address',
          prefixIcon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Email is required';
            if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
              return 'Enter a valid email address';
            }
            return null;
          },
        ),
      ),
    );
  }

  /// Password text field with visibility toggle.
  Widget _buildPasswordField(AuthProvider auth) {
    return FadeTransition(
      opacity: _passwordFade,
      child: SlideTransition(
        position: _passwordSlide,
        child: _InputField(
          controller: _passwordController,
          enabled: !auth.isLoading,
          hint: 'Password',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.textTertiary,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) {
              return 'Password is required';
            }
            if (v.length < 8) {
              return 'Password must be at least 8 characters';
            }
            if (!RegExp(r'\d').hasMatch(v)) {
              return 'Password must contain at least one number';
            }
            return null;
          },
        ),
      ),
    );
  }

  /// Error card — rendered only when [auth.error] is non-null.
  Widget _buildErrorCard(AuthProvider auth) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: auth.error == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AnimatedBuilder(
                animation: _shakeOffset,
                builder: (context, child) => Transform.translate(
                  offset: Offset(_shakeOffset.value, 0),
                  child: child,
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(15),
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(
                      left: BorderSide(color: AppColors.error, width: 3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          auth.error!,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// Primary login button — Bebas Neue label, scale-on-press, loading state.
  Widget _buildLoginButton(AuthProvider auth) {
    return FadeTransition(
      opacity: _buttonFade,
      child: SlideTransition(
        position: _buttonSlide,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Listener gives us raw pointer events without interfering
            // with ElevatedButton's own InkWell gesture recognition.
            Listener(
              onPointerDown: (_) => setState(() => _buttonPressed = true),
              onPointerUp: (_) => setState(() => _buttonPressed = false),
              onPointerCancel: (_) => setState(() => _buttonPressed = false),
              child: AnimatedScale(
                scale: _buttonPressed ? 0.97 : 1.0,
                duration: const Duration(milliseconds: 100),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      disabledBackgroundColor:
                          AppColors.primary.withAlpha(160),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.background,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'LOGIN',
                                style: GoogleFonts.bebasNeue(
                                  fontSize: 20,
                                  letterSpacing: 3.5,
                                  color: AppColors.background,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.background,
                                size: 18,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Don't have an account? Register →" link.
  Widget _buildRegisterLink() {
    return FadeTransition(
      opacity: _buttonFade, // shares the button's stagger timing
      child: GestureDetector(
        onTap: () => context.go('/register'),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: "Don't have an account?  ",
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              TextSpan(
                text: 'Register →',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private widget ─────────────────────────────────────────────────────────────

/// Reusable input field styled for the white card (light-gray fill, 14 px radius).
///
/// Extracted to a [StatelessWidget] to keep build methods readable without
/// creating a separate file for a single-screen component.
class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  static const _radius = 14.0;
  static const _fill = AppColors.surfaceHighlight;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      style: GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.manrope(
          fontSize: 15,
          color: AppColors.textTertiary,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon:
            Icon(prefixIcon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        constraints: const BoxConstraints(minHeight: 52),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide:
              const BorderSide(color: AppColors.error, width: 2),
        ),
        errorStyle: GoogleFonts.manrope(
          fontSize: 12,
          color: AppColors.error,
          fontWeight: FontWeight.w500,
        ),
      ),
      validator: validator,
    );
  }
}

// ── Painter ────────────────────────────────────────────────────────────────────

/// Draws subtle diagonal stripes across the full screen.
///
/// The fill colour is white at ~4 % opacity so stripes read only on
/// the deep-blue header panel (they're invisible on the white card).
class _DiagonalStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(10) // ≈ 4 %
      ..style = PaintingStyle.fill;

    const stripeWidth = 26.0;
    const gap = 58.0;

    // Iterate from left of screen minus full-height offset so stripes
    // cover the top-left corner cleanly.
    for (double x = -size.height; x < size.width + size.height; x += stripeWidth + gap) {
      final path = Path()
        ..moveTo(x, 0)
        ..lineTo(x + stripeWidth, 0)
        ..lineTo(x + stripeWidth + size.height, size.height)
        ..lineTo(x + size.height, size.height)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_DiagonalStripePainter _) => false;
}
