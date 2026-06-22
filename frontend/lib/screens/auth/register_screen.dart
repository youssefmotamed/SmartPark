// register_screen.dart — S03: Registration screen
// Split layout: dark navy header with back button + title, white card slides up from below.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  // ── Form state ─────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _fullNameController    = TextEditingController();
  final _studentIdController   = TextEditingController();
  final _emailController       = TextEditingController();
  final _passwordController    = TextEditingController();
  final _confirmController     = TextEditingController();
  final _plateController       = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _buttonPressed   = false;

  // ── Animation controllers ──────────────────────────────────────────────────
  late final AnimationController _bgController;
  late final AnimationController _entryController;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _cardSlide;

  // Form field stagger
  late final Animation<double> _nameFade;
  late final Animation<Offset> _nameSlide;
  late final Animation<double> _idFade;
  late final Animation<Offset> _idSlide;
  late final Animation<double> _emailFade;
  late final Animation<Offset> _emailSlide;
  late final Animation<double> _passwordFade;
  late final Animation<Offset> _passwordSlide;
  late final Animation<double> _confirmFade;
  late final Animation<Offset> _confirmSlide;
  late final Animation<double> _plateFade;
  late final Animation<Offset> _plateSlide;
  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;

  // ── Light-card color palette ───────────────────────────────────────────────
  static const _kCardText    = Color(0xFF1A2035);
  static const _kCardTextSub = Color(0xFF6B7280);
  static const _kButtonColor = Color(0xFFEDB82A);

  @override
  void initState() {
    super.initState();

    // Card entrance
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _headerFade = CurvedAnimation(
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

    // Form stagger — 900 ms, 7 fields × 60 ms steps, each item 350 ms
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    const slideStart = Offset(0, 0.4);
    const c = Curves.easeOutCubic;

    _nameFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.000, 0.389, curve: c)));
    _nameSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.000, 0.389, curve: c)));

    _idFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.067, 0.456, curve: c)));
    _idSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.067, 0.456, curve: c)));

    _emailFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.133, 0.522, curve: c)));
    _emailSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.133, 0.522, curve: c)));

    _passwordFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.200, 0.589, curve: c)));
    _passwordSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.200, 0.589, curve: c)));

    _confirmFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.267, 0.656, curve: c)));
    _confirmSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.267, 0.656, curve: c)));

    _plateFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.333, 0.722, curve: c)));
    _plateSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.333, 0.722, curve: c)));

    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.400, 0.800, curve: c)));
    _buttonSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.400, 0.800, curve: c)));

    _bgController.forward();
    Future.delayed(
      const Duration(milliseconds: 360),
      () { if (mounted) _entryController.forward(); },
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _plateController.dispose();
    _bgController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthProvider>().clearError();

    final success = await context.read<AuthProvider>().register(
      fullName:    _fullNameController.text.trim(),
      studentId:   _studentIdController.text.trim(),
      email:       _emailController.text.trim(),
      password:    _passwordController.text,
      plateNumber: _plateController.text.trim().toUpperCase(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please sign in.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/login');
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
              // ── Dark header with back button + title ───────────────────────
              SafeArea(
                bottom: false,
                child: FadeTransition(
                  opacity: _headerFade,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                    child: _buildHeader(),
                  ),
                ),
              ),

              // ── White card slides up ───────────────────────────────────────
              Expanded(
                child: ClipRect(
                  child: SlideTransition(
                    position: _cardSlide,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(28)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                        child: Form(
                          key: _formKey,
                          autovalidateMode: AutovalidateMode.disabled,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildFieldRow(_nameFade, _nameSlide,
                                  _buildFullNameField(auth)),
                              const SizedBox(height: 16),
                              _buildFieldRow(_idFade, _idSlide,
                                  _buildStudentIdField(auth)),
                              const SizedBox(height: 16),
                              _buildFieldRow(_emailFade, _emailSlide,
                                  _buildEmailField(auth)),
                              const SizedBox(height: 16),
                              _buildFieldRow(_passwordFade, _passwordSlide,
                                  _buildPasswordField(auth)),
                              const SizedBox(height: 16),
                              _buildFieldRow(_confirmFade, _confirmSlide,
                                  _buildConfirmField(auth)),
                              const SizedBox(height: 16),
                              _buildFieldRow(_plateFade, _plateSlide,
                                  _buildPlateField(auth)),
                              const SizedBox(height: 24),
                              _buildErrorCard(auth),
                              _buildRegisterButton(auth),
                              const SizedBox(height: 20),
                              _buildLoginLink(),
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

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => context.go('/login'),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha(40)),
            ),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Account',
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            Text(
              'Register as a university student',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: Colors.white.withAlpha(160),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFieldRow(
    Animation<double> fade,
    Animation<Offset> slide,
    Widget child,
  ) {
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }

  Widget _buildFullNameField(AuthProvider auth) {
    return _LightRegField(
      controller: _fullNameController,
      enabled: !auth.isLoading,
      hint: 'Walid Ahmed',
      label: 'Full Name',
      prefixIcon: LucideIcons.user,
      textInputAction: TextInputAction.next,
      keyboardType: TextInputType.name,
      textCapitalization: TextCapitalization.words,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Full name is required';
        if (v.trim().length < 3) return 'Name must be at least 3 characters';
        return null;
      },
    );
  }

  Widget _buildStudentIdField(AuthProvider auth) {
    return _LightRegField(
      controller: _studentIdController,
      enabled: !auth.isLoading,
      hint: '20221234',
      label: 'Student ID',
      prefixIcon: LucideIcons.creditCard,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Student ID is required';
        if (!RegExp(r'^\d+$').hasMatch(v.trim())) {
          return 'Student ID must contain digits only';
        }
        if (v.trim().length < 5) return 'Must be at least 5 digits';
        return null;
      },
    );
  }

  Widget _buildEmailField(AuthProvider auth) {
    return _LightRegField(
      controller: _emailController,
      enabled: !auth.isLoading,
      hint: 'walid@student.edu',
      label: 'Email Address',
      prefixIcon: LucideIcons.mail,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email is required';
        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
          return 'Enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField(AuthProvider auth) {
    return _LightRegField(
      controller: _passwordController,
      enabled: !auth.isLoading,
      hint: 'Min. 8 characters',
      label: 'Password',
      prefixIcon: LucideIcons.lock,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
          color: const Color(0xFF9CA3AF),
          size: 20,
        ),
        onPressed: () =>
            setState(() => _obscurePassword = !_obscurePassword),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required';
        if (v.length < 8) return 'Password must be at least 8 characters';
        if (!RegExp(r'\d').hasMatch(v)) {
          return 'Password must contain at least one number';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmField(AuthProvider auth) {
    return _LightRegField(
      controller: _confirmController,
      enabled: !auth.isLoading,
      hint: 'Repeat password',
      label: 'Confirm Password',
      prefixIcon: LucideIcons.lock,
      obscureText: _obscureConfirm,
      textInputAction: TextInputAction.next,
      suffixIcon: IconButton(
        icon: Icon(
          _obscureConfirm ? LucideIcons.eye : LucideIcons.eyeOff,
          color: const Color(0xFF9CA3AF),
          size: 20,
        ),
        onPressed: () =>
            setState(() => _obscureConfirm = !_obscureConfirm),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Please confirm your password';
        if (v != _passwordController.text) return 'Passwords do not match';
        return null;
      },
    );
  }

  Widget _buildPlateField(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LightRegField(
          controller: _plateController,
          enabled: !auth.isLoading,
          hint: 'ABC 1234',
          label: 'License Plate Number',
          prefixIcon: LucideIcons.car,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.characters,
          useMonoFont: true,
          onFieldSubmitted: (_) => _handleRegister(),
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'License plate is required';
            }
            if (v.trim().length < 3) {
              return 'Enter a valid license plate';
            }
            return null;
          },
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'This will be linked to your parking badge',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: _kCardTextSub,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(AuthProvider auth) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: auth.error == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
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
    );
  }

  Widget _buildRegisterButton(AuthProvider auth) {
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
                onPressed: auth.isLoading ? null : _handleRegister,
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
                        'Create Account',
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

  Widget _buildLoginLink() {
    return FadeTransition(
      opacity: _buttonFade,
      child: GestureDetector(
        onTap: () => context.go('/login'),
        child: RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Already have an account? ',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: _kCardTextSub,
                  fontWeight: FontWeight.w400,
                ),
              ),
              TextSpan(
                text: 'Sign In',
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
}

// ── Light-themed input field for the white card ────────────────────────────────

class _LightRegField extends StatelessWidget {
  const _LightRegField({
    required this.controller,
    required this.hint,
    required this.label,
    required this.prefixIcon,
    this.enabled = true,
    this.obscureText = false,
    this.useMonoFont = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final String label;
  final IconData prefixIcon;
  final bool enabled;
  final bool obscureText;
  final bool useMonoFont;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;

  static const _radius    = 14.0;
  static const _fill      = Color(0xFFF3F4F8);
  static const _border    = Color(0xFFE5E7EB);
  static const _textColor = Color(0xFF1A2035);
  static const _hintColor = Color(0xFF9CA3AF);
  static const _iconColor = Color(0xFF9CA3AF);
  static const _labelColor = Color(0xFF374151);
  static const _accent    = Color(0xFFEDB82A);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _labelColor,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          onFieldSubmitted: onFieldSubmitted,
          style: useMonoFont
              ? GoogleFonts.jetBrainsMono(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _textColor,
                  letterSpacing: 1.5,
                )
              : GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _textColor,
                ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: useMonoFont
                ? GoogleFonts.jetBrainsMono(
                    fontSize: 15,
                    color: _hintColor,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.5,
                  )
                : GoogleFonts.manrope(
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
              borderSide: const BorderSide(color: _accent, width: 2),
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
        ),
      ],
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
