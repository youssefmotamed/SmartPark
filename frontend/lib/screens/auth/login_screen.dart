// login_screen.dart — S02: Login screen
// Split layout: dark navy header with P-badge logo, white card slides up from below.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';

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
  late final AnimationController _bgController;
  late final AnimationController _formController;
  late final AnimationController _shakeController;

  late final Animation<double> _logoFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardHeaderFade;
  late final Animation<double> _emailFade;
  late final Animation<Offset> _emailSlide;
  late final Animation<double> _passwordFade;
  late final Animation<Offset> _passwordSlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;
  late final Animation<double> _shakeOffset;

  // ── Light-card color palette ───────────────────────────────────────────────
  static const _kCardText    = Color(0xFF1A2035);
  static const _kCardTextSub = Color(0xFF6B7280);
  static const _kFieldBorder = Color(0xFFE5E7EB);
  static const _kButtonColor = Color(0xFFEDB82A);
  static const _kDemoBg     = Color(0xFFF5F7FA);

  // ── Demo credentials ───────────────────────────────────────────────────────
  static const _demoUsers = [
    _DemoUser('youssef@smartpark.com', 'youssef123', 'STUDENT', Color(0xFF26A69A)),
    _DemoUser('guard@smartpark.com',  'Guard@2026', 'GUARD',   Color(0xFF455A64)),
    _DemoUser('admin@smartpark.com',  'Admin@2026', 'ADMIN',   Color(0xFFE53935)),
  ];

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    _logoFade = CurvedAnimation(
      parent: _bgController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeIn),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bgController,
      curve: const Interval(0.0, 0.88, curve: Curves.easeOutQuart),
    ));

    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );

    const c = Curves.easeOutCubic;
    const slideStart = Offset(0, 0.18);

    _cardHeaderFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.00, 0.50, curve: c)),
    );
    _emailFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.12, 0.62, curve: c)),
    );
    _emailSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.12, 0.62, curve: c)),
    );
    _passwordFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.27, 0.77, curve: c)),
    );
    _passwordSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.27, 0.77, curve: c)),
    );
    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.42, 1.00, curve: c)),
    );
    _buttonSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
      CurvedAnimation(parent: _formController, curve: const Interval(0.42, 1.00, curve: c)),
    );

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

  void _fillDemo(_DemoUser user) {
    _emailController.text = user.email;
    _passwordController.text = user.password;
    context.read<AuthProvider>().clearError();
    FocusScope.of(context).unfocus();
  }

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
      case 'GUARD': context.go('/guard/home');
      case 'ADMIN': context.go('/admin/home');
      default:      context.go('/student/home');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _DiagonalStripePainter())),
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: FadeTransition(
                  opacity: _logoFade,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
                    child: _buildLogoArea(),
                  ),
                ),
              ),
              Expanded(
                child: ClipRect(
                  child: SlideTransition(
                    position: _cardSlide,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildCardHeader(),
                              const SizedBox(height: 28),
                              _buildEmailField(auth),
                              const SizedBox(height: 16),
                              _buildPasswordField(auth),
                              const SizedBox(height: 20),
                              _buildErrorCard(auth),
                              _buildLoginButton(auth),
                              const SizedBox(height: 20),
                              _buildRegisterLink(),
                              const SizedBox(height: 28),
                              _buildQuickDemoSection(),
                              const SizedBox(height: 32),
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

  Widget _buildLogoArea() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _kButtonColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  'P',
                  style: GoogleFonts.manrope(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Smart',
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  TextSpan(
                    text: 'Park',
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _kButtonColor,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'UNIVERSITY PARKING SYSTEM',
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white.withAlpha(120),
            letterSpacing: 2.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCardHeader() {
    return FadeTransition(
      opacity: _cardHeaderFade,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome Back',
            style: GoogleFonts.manrope(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _kCardText,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Sign in to access your parking account',
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: _kCardTextSub,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField(AuthProvider auth) {
    return FadeTransition(
      opacity: _emailFade,
      child: SlideTransition(
        position: _emailSlide,
        child: _LightInputField(
          controller: _emailController,
          enabled: !auth.isLoading,
          hint: 'you@university.edu',
          prefixIcon: Icons.alternate_email_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          accentColor: _kButtonColor,
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

  Widget _buildPasswordField(AuthProvider auth) {
    return FadeTransition(
      opacity: _passwordFade,
      child: SlideTransition(
        position: _passwordSlide,
        child: _LightInputField(
          controller: _passwordController,
          enabled: !auth.isLoading,
          hint: 'Enter your password',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleLogin(),
          accentColor: _kButtonColor,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: _kCardTextSub,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            return null;
          },
        ),
      ),
    );
  }

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

  Widget _buildLoginButton(AuthProvider auth) {
    return FadeTransition(
      opacity: _buttonFade,
      child: SlideTransition(
        position: _buttonSlide,
        child: Listener(
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
                  backgroundColor: _kButtonColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _kButtonColor.withAlpha(160),
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
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Sign In',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return FadeTransition(
      opacity: _buttonFade,
      child: GestureDetector(
        onTap: () => context.go('/register'),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: "Don't have an account? ",
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: _kCardTextSub,
                  fontWeight: FontWeight.w400,
                ),
              ),
              TextSpan(
                text: 'Register',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: _kCardText,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDemoSection() {
    return FadeTransition(
      opacity: _buttonFade,
      child: Container(
        decoration: BoxDecoration(
          color: _kDemoBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kFieldBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Text(
                'QUICK DEMO ACCESS',
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _kCardTextSub,
                  letterSpacing: 1.8,
                ),
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
            ..._demoUsers.asMap().entries.map((entry) {
              final i = entry.key;
              final user = entry.value;
              final isLast = i == _demoUsers.length - 1;
              return Column(
                children: [
                  InkWell(
                    onTap: () => _fillDemo(user),
                    borderRadius: BorderRadius.vertical(
                      bottom: isLast ? const Radius.circular(16) : Radius.zero,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 13),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.email,
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _kCardText,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: user.badgeColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              user.role,
                              style: GoogleFonts.manrope(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Data ───────────────────────────────────────────────────────────────────────

class _DemoUser {
  final String email;
  final String password;
  final String role;
  final Color badgeColor;
  const _DemoUser(this.email, this.password, this.role, this.badgeColor);
}

// ── Light-themed input field for the white card ────────────────────────────────

class _LightInputField extends StatelessWidget {
  const _LightInputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    required this.accentColor,
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
  final Color accentColor;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  static const _radius    = 14.0;
  static const _fill      = Color(0xFFF3F4F8);
  static const _border    = Color(0xFFE5E7EB);
  static const _textColor = Color(0xFF1A2035);
  static const _hintColor = Color(0xFF9CA3AF);
  static const _iconColor = Color(0xFF9CA3AF);

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
        color: _textColor,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.manrope(
          fontSize: 15,
          color: _hintColor,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Icon(prefixIcon, color: _iconColor, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _fill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        constraints: const BoxConstraints(minHeight: 52),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
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

class _DiagonalStripePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(10)
      ..style = PaintingStyle.fill;

    const stripeWidth = 26.0;
    const gap = 58.0;

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
