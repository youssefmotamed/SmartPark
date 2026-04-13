// register_screen.dart — S03: Registration screen for new SmartPark students
// Flat scrollable layout with staggered slide-up animations.
// Cohesive with login screen: same dark palette, Bebas Neue × Manrope, Lucide icons.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/app_typography.dart';
import '../../config/colors.dart';
import '../../providers/auth_provider.dart';

/// S03 — Registration screen for new student accounts.
///
/// Phase 0: catches [UnimplementedError] from [AuthProvider.register],
/// shows a success snackbar, and redirects to `/login` so the flow is testable.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  // ── Form ───────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _plateController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _buttonPressed = false;

  // ── Entry animations ───────────────────────────────────────────────────────
  // Single controller, 800 ms total, drives 8 staggered pairs (fade + slide).
  // Interval math: delay 0–420 ms in 60 ms steps, each item 350 ms long.
  // start = delayMs / 800 ; end = (delayMs + 350) / 800

  late final AnimationController _entryController;

  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
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

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Shared start offset — 50 % of each widget's height ≈ 24–28 px on 52 px fields.
    const slideStart = Offset(0, 0.5);
    const c = Curves.easeOutCubic;

    // Header — delay 0 ms → [0.000, 0.438]
    _headerFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.000, 0.438, curve: c)));
    _headerSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.000, 0.438, curve: c)));

    // Full Name — delay 60 ms → [0.075, 0.513]
    _nameFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.075, 0.513, curve: c)));
    _nameSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.075, 0.513, curve: c)));

    // Student ID — delay 120 ms → [0.150, 0.588]
    _idFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.150, 0.588, curve: c)));
    _idSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.150, 0.588, curve: c)));

    // Email — delay 180 ms → [0.225, 0.663]
    _emailFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.225, 0.663, curve: c)));
    _emailSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.225, 0.663, curve: c)));

    // Password — delay 240 ms → [0.300, 0.738]
    _passwordFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.300, 0.738, curve: c)));
    _passwordSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.300, 0.738, curve: c)));

    // Confirm Password — delay 300 ms → [0.375, 0.813]
    _confirmFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.375, 0.813, curve: c)));
    _confirmSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.375, 0.813, curve: c)));

    // License Plate — delay 360 ms → [0.450, 0.888]
    _plateFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.450, 0.888, curve: c)));
    _plateSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.450, 0.888, curve: c)));

    // Button + link — delay 420 ms → [0.525, 0.963]
    _buttonFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.525, 0.963, curve: c)));
    _buttonSlide = Tween<Offset>(begin: slideStart, end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.525, 0.963, curve: c)));

    _entryController.forward();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _studentIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _plateController.dispose();
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
        SnackBar(
          content: Text(
            'Account created! Please log in.',
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
          ),
          backgroundColor: AppColors.surfaceLight,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/login');
    }
    // If not success: error is shown via context.watch<AuthProvider>().error
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
          // Subtle radial gradient at top — primary at 4 % opacity.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.1,
                  colors: [
                    AppColors.primary.withAlpha(10), // ≈ 4 %
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main scrollable content.
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.disabled,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    _buildBackButton(),
                    const SizedBox(height: 20),
                    _buildHeader(),
                    const SizedBox(height: 32),
                    _buildFullNameField(auth),
                    const SizedBox(height: 16),
                    _buildStudentIdField(auth),
                    const SizedBox(height: 16),
                    _buildEmailField(auth),
                    const SizedBox(height: 16),
                    _buildPasswordField(auth),
                    const SizedBox(height: 16),
                    _buildConfirmPasswordField(auth),
                    const SizedBox(height: 16),
                    _buildPlateField(auth),
                    const SizedBox(height: 24),
                    _buildErrorCard(auth),
                    _buildRegisterButton(auth),
                    const SizedBox(height: 24),
                    _buildLoginLink(),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section builders ───────────────────────────────────────────────────────

  /// Back arrow — returns to login screen.
  Widget _buildBackButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => context.go('/login'),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Icon(
            LucideIcons.arrowLeft,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }

  /// Screen title and subtitle with primary left-border accent.
  Widget _buildHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Electric-blue vertical rule — automotive dashboard accent.
            Container(
              width: 3,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Account', style: AppTypography.displayMedium),
                const SizedBox(height: 4),
                Text('Join Smart Park', style: AppTypography.bodyMedium),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Full name input.
  Widget _buildFullNameField(AuthProvider auth) {
    return FadeTransition(
      opacity: _nameFade,
      child: SlideTransition(
        position: _nameSlide,
        child: _RegInputField(
          controller: _fullNameController,
          enabled: !auth.isLoading,
          hint: 'Full name',
          prefixIcon: LucideIcons.user,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Full name is required';
            if (v.trim().length < 3) return 'Name must be at least 3 characters';
            return null;
          },
        ),
      ),
    );
  }

  /// Student ID input with helper text.
  Widget _buildStudentIdField(AuthProvider auth) {
    return FadeTransition(
      opacity: _idFade,
      child: SlideTransition(
        position: _idSlide,
        child: _RegInputField(
          controller: _studentIdController,
          enabled: !auth.isLoading,
          hint: 'Student ID',
          prefixIcon: LucideIcons.hash,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          helperText: 'Your university student ID (e.g., 20221234)',
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Student ID is required';
            if (!RegExp(r'^\d+$').hasMatch(v.trim())) {
              return 'Student ID must contain digits only';
            }
            if (v.trim().length < 5) return 'Student ID must be at least 5 digits';
            if (v.trim().length > 20) return 'Student ID must be at most 20 digits';
            return null;
          },
        ),
      ),
    );
  }

  /// Email input.
  Widget _buildEmailField(AuthProvider auth) {
    return FadeTransition(
      opacity: _emailFade,
      child: SlideTransition(
        position: _emailSlide,
        child: _RegInputField(
          controller: _emailController,
          enabled: !auth.isLoading,
          hint: 'Email address',
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
        ),
      ),
    );
  }

  /// Password input with visibility toggle.
  Widget _buildPasswordField(AuthProvider auth) {
    return FadeTransition(
      opacity: _passwordFade,
      child: SlideTransition(
        position: _passwordSlide,
        child: _RegInputField(
          controller: _passwordController,
          enabled: !auth.isLoading,
          hint: 'Password',
          prefixIcon: LucideIcons.lock,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? LucideIcons.eye : LucideIcons.eyeOff,
              color: AppColors.textTertiary,
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
        ),
      ),
    );
  }

  /// Confirm password input — must match [_passwordController].
  Widget _buildConfirmPasswordField(AuthProvider auth) {
    return FadeTransition(
      opacity: _confirmFade,
      child: SlideTransition(
        position: _confirmSlide,
        child: _RegInputField(
          controller: _confirmController,
          enabled: !auth.isLoading,
          hint: 'Confirm password',
          prefixIcon: LucideIcons.lock,
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.next,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm ? LucideIcons.eye : LucideIcons.eyeOff,
              color: AppColors.textTertiary,
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
        ),
      ),
    );
  }

  /// License plate input — mono font, auto-uppercase.
  Widget _buildPlateField(AuthProvider auth) {
    return FadeTransition(
      opacity: _plateFade,
      child: SlideTransition(
        position: _plateSlide,
        child: _RegInputField(
          controller: _plateController,
          enabled: !auth.isLoading,
          hint: 'License plate (e.g., ABC 123)',
          prefixIcon: LucideIcons.car,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
          textCapitalization: TextCapitalization.characters,
          inputStyle: AppTypography.mono,
          onFieldSubmitted: (_) => _handleRegister(),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'License plate is required';
            if (v.trim().length < 3) {
              return 'Enter a valid license plate number';
            }
            return null;
          },
        ),
      ),
    );
  }

  /// Error banner — shown when [auth.error] is non-null, slides open.
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
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(26), // 10 %
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(color: AppColors.error, width: 3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.alertCircle,
                      color: AppColors.error,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        auth.error!,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Primary register button — scale-on-press, loading spinner.
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
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  disabledBackgroundColor: AppColors.primary.withAlpha(160),
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
                          strokeWidth: 2,
                          color: AppColors.background,
                        ),
                      )
                    : Text(
                        'CREATE ACCOUNT',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.background,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// "Already have an account? Login →" link.
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
                text: 'Already have an account?  ',
                style: AppTypography.bodyMedium,
              ),
              TextSpan(
                text: 'Login →',
                style: AppTypography.bodyMedium.copyWith(
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

/// Reusable styled input field for the registration form.
///
/// Matches the visual spec of [LoginScreen]'s _InputField:
/// 14 px radius, [AppColors.surfaceLight] fill, 1.5 px [AppColors.divider] border.
/// Adds [helperText], [textCapitalization], and [inputStyle] for register-specific needs.
class _RegInputField extends StatelessWidget {
  const _RegInputField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputStyle,
    this.onFieldSubmitted,
    this.suffixIcon,
    this.helperText,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  /// Overrides the default Manrope input style (e.g. pass [AppTypography.mono]
  /// for the license plate field).
  final TextStyle? inputStyle;

  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffixIcon;

  /// Optional hint shown below the field when there is no error.
  final String? helperText;

  final FormFieldValidator<String>? validator;

  static const _radius = 14.0;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      onFieldSubmitted: onFieldSubmitted,
      style: inputStyle ??
          GoogleFonts.manrope(
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
        prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        constraints: const BoxConstraints(minHeight: 52),
        helperText: helperText,
        helperStyle: AppTypography.bodySmall,
        helperMaxLines: 2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(
            color: AppColors.divider,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(
            color: AppColors.divider,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
        errorMaxLines: 2,
      ),
      validator: validator,
    );
  }
}
