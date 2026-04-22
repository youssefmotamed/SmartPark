// user_detail_screen.dart — S30: Admin create / view / edit a single user.
// Three modes: create (isCreateMode=true), view (default), edit (toggled).
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../providers/admin_provider.dart';

/// S30 — User Detail / Edit / Create screen.
///
/// Pass [userId] to load an existing user (view → edit toggle).
/// Pass [isCreateMode] = true to open the create-user form.
class UserDetailScreen extends StatefulWidget {
  final int?  userId;
  final bool  isCreateMode;

  const UserDetailScreen({
    super.key,
    this.userId,
    this.isCreateMode = false,
  });

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final _fullNameController  = TextEditingController();
  final _emailController     = TextEditingController();
  final _passwordController  = TextEditingController();
  final _studentIdController = TextEditingController();
  final _plateController     = TextEditingController();

  bool    _isEditMode      = false;
  bool    _obscurePassword = true;
  String  _selectedRole    = 'GUARD';
  bool    _isOperating     = false;

  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isCreateMode) {
      _isEditMode = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<AdminProvider>().loadUser(widget.userId!).then((_) {
          if (!mounted) return;
          final user = context.read<AdminProvider>().selectedUser;
          if (user != null) {
            _fullNameController.text = user.fullName;
            _emailController.text    = user.email;
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _studentIdController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatDate(DateTime dt) =>
      '${dt.day} ${_months[dt.month - 1]} ${dt.year}';

  Color _roleColor(String role) {
    switch (role) {
      case 'STUDENT': return AppColors.primary;
      case 'GUARD':   return AppColors.warning;
      case 'ADMIN':   return AppColors.error;
      default:        return AppColors.textSecondary;
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'STUDENT': return 'Student';
      case 'GUARD':   return 'Guard';
      case 'ADMIN':   return 'Admin';
      default:        return role;
    }
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _handleSave() async {
    final provider = context.read<AdminProvider>();
    provider.clearOperationError();
    setState(() => _isOperating = true);

    if (widget.isCreateMode) {
      final userData = <String, dynamic>{
        'fullName': _fullNameController.text.trim(),
        'email':    _emailController.text.trim(),
        'password': _passwordController.text,
        'role':     _selectedRole,
      };
      if (_selectedRole == 'STUDENT') {
        userData['studentId']   = _studentIdController.text.trim();
        userData['plateNumber'] =
            _plateController.text.trim().toUpperCase();
      }

      final result = await provider.createUser(userData);
      if (!mounted) return;
      setState(() => _isOperating = false);

      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:         Text('User created successfully'),
          backgroundColor: AppColors.success,
          behavior:        SnackBarBehavior.floating,
        ));
        context.pop();
      }
    } else {
      final success = await provider.updateUser(
        widget.userId!,
        fullName: _fullNameController.text.trim(),
        email:    _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isOperating = false);

      if (success) {
        setState(() => _isEditMode = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:         Text('User updated successfully'),
          backgroundColor: AppColors.success,
          behavior:        SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Deactivate / reactivate ────────────────────────────────────────────────

  Future<void> _handleToggleActive() async {
    final provider = context.read<AdminProvider>();
    final user     = provider.selectedUser;
    if (user == null) return;

    final action = user.isActive ? 'deactivate' : 'reactivate';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius)),
        title: Text(
          user.isActive ? 'Deactivate Account' : 'Reactivate Account',
          style: AppTypography.displaySmall,
        ),
        content: Text(
          'Are you sure you want to $action ${user.fullName}?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              user.isActive ? 'Deactivate' : 'Reactivate',
              style: AppTypography.labelMedium.copyWith(
                color: user.isActive ? AppColors.warning : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isOperating = true);
    final ok = await provider.deleteUser(user.id);
    if (!mounted) return;
    setState(() => _isOperating = false);

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            user.isActive ? 'Account deactivated' : 'Account reactivated'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ));
      context.pop();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final user     = provider.selectedUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.isCreateMode ? 'Add User' : 'User Detail',
          style: AppTypography.displaySmall,
        ),
        centerTitle: true,
        actions: [
          if (!widget.isCreateMode && !_isEditMode)
            IconButton(
              icon: const Icon(LucideIcons.pencil,
                  size: 20, color: AppColors.textSecondary),
              onPressed: () => setState(() => _isEditMode = true),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      body: () {
        if (!widget.isCreateMode && provider.isLoadingUser) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        if (!widget.isCreateMode && user == null) {
          return Center(
            child: Text('User not found', style: AppTypography.bodyMedium),
          );
        }
        return _buildForm(provider, user);
      }(),
    );
  }

  // ── Form ───────────────────────────────────────────────────────────────────

  Widget _buildForm(dynamic provider, dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Avatar + name header (view/edit mode only) ─────────────────
          if (!widget.isCreateMode && user != null) ...[
            Center(
              child: Column(
                children: [
                  Container(
                    width:  72,
                    height: 72,
                    decoration: BoxDecoration(
                      color:  _roleColor(user.role).withValues(alpha: 0.20),
                      shape:  BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : '?',
                        style: AppTypography.displaySmall
                            .copyWith(color: _roleColor(user.role)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.fullName, style: AppTypography.displaySmall),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _roleColor(user.role).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _roleLabel(user.role),
                      style: AppTypography.labelSmall
                          .copyWith(color: _roleColor(user.role)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],

          // ── Full Name ────────────────────────────────────────────────────
          _FieldLabel('Full Name'),
          const SizedBox(height: 6),
          _isEditMode || widget.isCreateMode
              ? _buildTextField(
                  controller: _fullNameController,
                  hint: 'e.g. Ahmed Mohamed',
                )
              : _buildReadOnlyText(user?.fullName ?? ''),

          const SizedBox(height: 16),

          // ── Email ────────────────────────────────────────────────────────
          _FieldLabel('Email'),
          const SizedBox(height: 6),
          _isEditMode || widget.isCreateMode
              ? _buildTextField(
                  controller:   _emailController,
                  hint:         'user@example.com',
                  keyboardType: TextInputType.emailAddress,
                )
              : _buildReadOnlyText(user?.email ?? ''),

          // ── Create-only fields ───────────────────────────────────────────
          if (widget.isCreateMode) ...[
            const SizedBox(height: 16),

            // Role
            _FieldLabel('Role'),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color:        AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
                border: Border.all(color: AppColors.divider),
              ),
              child: DropdownButton<String>(
                value:         _selectedRole,
                isExpanded:    true,
                underline:     const SizedBox.shrink(),
                dropdownColor: AppColors.surfaceLight,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textPrimary),
                items: const [
                  DropdownMenuItem(value: 'GUARD',   child: Text('Guard')),
                  DropdownMenuItem(value: 'STUDENT', child: Text('Student')),
                  DropdownMenuItem(value: 'ADMIN',   child: Text('Admin')),
                ],
                onChanged: (v) =>
                    setState(() => _selectedRole = v ?? 'GUARD'),
              ),
            ),

            const SizedBox(height: 16),

            // Password
            _FieldLabel('Password'),
            const SizedBox(height: 6),
            _buildTextField(
              controller:      _passwordController,
              hint:            'Minimum 8 characters',
              obscureText:     _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? LucideIcons.eye
                      : LucideIcons.eyeOff,
                  size:  18,
                  color: AppColors.textTertiary,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),

            // Student-only fields
            if (_selectedRole == 'STUDENT') ...[
              const SizedBox(height: 16),
              _FieldLabel('Student ID'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: _studentIdController,
                hint:       'University student ID',
              ),
              const SizedBox(height: 16),
              _FieldLabel('Plate Number'),
              const SizedBox(height: 6),
              _buildTextField(
                controller:       _plateController,
                hint:             'e.g. ABC 1234',
                monoFont:         true,
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ],

          // ── View-only fields ──────────────────────────────────────────────
          if (!widget.isCreateMode && !_isEditMode && user != null) ...[
            const SizedBox(height: 16),
            _InfoRow(
              label: 'Account Status',
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: user.isActive
                      ? AppColors.success.withValues(alpha: 0.15)
                      : AppColors.textTertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  user.isActive ? 'Active' : 'Inactive',
                  style: AppTypography.labelSmall.copyWith(
                    color: user.isActive
                        ? AppColors.success
                        : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow(
              label: 'Member Since',
              child: Text(
                _formatDate(user.createdAt),
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textPrimary),
              ),
            ),
          ],

          const SizedBox(height: 28),

          // ── Action buttons (view mode only) ───────────────────────────────
          if (!widget.isCreateMode && !_isEditMode && user != null) ...[
            SizedBox(
              width:  double.infinity,
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                onPressed: () => setState(() => _isEditMode = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppSpacing.buttonRadius)),
                ),
                child: Text('Edit User',
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.background)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width:  double.infinity,
              height: AppSpacing.buttonHeight,
              child: OutlinedButton(
                onPressed: _isOperating ? null : _handleToggleActive,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: user.isActive
                        ? AppColors.warning
                        : AppColors.success,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppSpacing.buttonRadius)),
                ),
                child: _isOperating
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.warning),
                      )
                    : Text(
                        user.isActive
                            ? 'Deactivate Account'
                            : 'Reactivate',
                        style: AppTypography.labelLarge.copyWith(
                          color: user.isActive
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                      ),
              ),
            ),
          ],

          // ── Save button (edit / create mode) ─────────────────────────────
          if (_isEditMode || widget.isCreateMode) ...[
            SizedBox(
              width:  double.infinity,
              height: AppSpacing.buttonHeight,
              child: ElevatedButton(
                onPressed: (_isOperating || provider.isOperating)
                    ? null
                    : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor:         AppColors.primary,
                  disabledBackgroundColor: AppColors.divider,
                  foregroundColor:         AppColors.background,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          AppSpacing.buttonRadius)),
                ),
                child: (_isOperating || provider.isOperating)
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        widget.isCreateMode
                            ? 'Create User'
                            : 'Save Changes',
                        style: AppTypography.labelLarge
                            .copyWith(color: AppColors.background),
                      ),
              ),
            ),
          ],

          // ── Operation error ───────────────────────────────────────────────
          if (provider.operationError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:  AppColors.error.withValues(alpha: 0.15),
                borderRadius:
                    BorderRadius.circular(AppSpacing.cardRadiusSmall),
                border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertCircle,
                      size: 16, color: AppColors.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      provider.operationError!,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Field helpers ──────────────────────────────────────────────────────────

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool monoFont = false,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller:         controller,
      keyboardType:       keyboardType,
      obscureText:        obscureText,
      textCapitalization: textCapitalization,
      style: monoFont
          ? GoogleFonts.jetBrainsMono(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              letterSpacing: 1.2,
            )
          : AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText:   hint,
        hintStyle:  AppTypography.bodyMedium,
        filled:     true,
        fillColor:  AppColors.surfaceLight,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide:   const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide:   const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.inputRadius),
          borderSide:   const BorderSide(
              color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildReadOnlyText(String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        value.isEmpty ? '—' : value,
        style: AppTypography.bodyLarge,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelMedium
          .copyWith(color: AppColors.textSecondary),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _InfoRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
        const Spacer(),
        child,
      ],
    );
  }
}
