// user_management_screen.dart — S29: Admin user list with search, role filter,
// infinite scroll, and a FAB to create new users.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../config/colors.dart';
import '../../config/app_typography.dart';
import '../../config/app_spacing.dart';
import '../../models/admin_user.dart';
import '../../providers/admin_provider.dart';

/// S29 — User Management screen.
///
/// Displays a paginated, searchable, role-filtered list of all users.
/// Tapping a row navigates to [UserDetailScreen]. FAB opens create flow.
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController       _scrollController = ScrollController();
  Timer?   _debounceTimer;
  String?  _selectedRole; // null = All

  static const _roleFilters = [
    (label: 'All',      value: null),
    (label: 'Students', value: 'STUDENT'),
    (label: 'Guards',   value: 'GUARD'),
    (label: 'Admins',   value: 'ADMIN'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  // ── Scroll + search ────────────────────────────────────────────────────────

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<AdminProvider>().loadMoreUsers();
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      context.read<AdminProvider>().loadUsers(
        search: value.trim().isEmpty ? null : value.trim(),
        role:   _selectedRole,
      );
    });
  }

  void _setRole(String? role) {
    setState(() => _selectedRole = role);
    context.read<AdminProvider>().loadUsers(
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      role: role,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              color: AppColors.textSecondary),
          onPressed: () => context.canPop() ? context.pop() : null,
        ),
        title: Text('User Management', style: AppTypography.displaySmall),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.divider),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.userPlus, color: Colors.white),
        label: Text('Add User',
            style: AppTypography.labelMedium.copyWith(color: Colors.white)),
        onPressed: () => context.push('/admin/users/create'),
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller:    _searchController,
              onChanged:     _onSearchChanged,
              style:         AppTypography.bodyMedium
                  .copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText:   'Search by name or student ID',
                hintStyle:  AppTypography.bodyMedium,
                filled:     true,
                fillColor:  AppColors.surfaceLight,
                prefixIcon: const Icon(LucideIcons.search,
                    size: 18, color: AppColors.textTertiary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x,
                            size: 18, color: AppColors.textTertiary),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:   BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:   BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // ── Role filter chips ────────────────────────────────────────────
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemCount: _roleFilters.length,
              itemBuilder: (_, i) {
                final f          = _roleFilters[i];
                final isSelected = _selectedRole == f.value;
                return GestureDetector(
                  onTap: () => _setRole(f.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      f.label,
                      style: AppTypography.labelSmall.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // ── List ─────────────────────────────────────────────────────────
          Expanded(
            child: () {
              if (provider.isLoadingUsers && provider.users.isEmpty) {
                return _buildLoading();
              }
              if (provider.usersError != null && provider.users.isEmpty) {
                return _buildError(provider);
              }
              if (provider.users.isEmpty) {
                return _buildEmpty();
              }
              return _buildList(provider);
            }(),
          ),
        ],
      ),
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────

  Widget _buildList(AdminProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: provider.users.length + (provider.usersHasMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == provider.users.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2),
            ),
          );
        }
        return _UserRow(
          user:  provider.users[i],
          onTap: () => context.push('/admin/users/${provider.users[i].id}'),
        );
      },
    );
  }

  // ── Loading ────────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: 6,
      itemBuilder: (_, _) => Container(
        height: 72,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color:        AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ── Empty + Error ──────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.users,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text('No users found', style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildError(AdminProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenH),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle,
                size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(provider.usersError!,
                style: AppTypography.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<AdminProvider>().loadUsers(
                role:   _selectedRole,
                search: _searchController.text.trim().isEmpty
                    ? null : _searchController.text.trim(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.buttonRadius)),
              ),
              child: Text('Retry',
                  style: AppTypography.labelMedium
                      .copyWith(color: AppColors.background)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User row
// ─────────────────────────────────────────────────────────────────────────────

class _UserRow extends StatelessWidget {
  final AdminUser    user;
  final VoidCallback onTap;

  const _UserRow({required this.user, required this.onTap});

  Color _roleColor() {
    switch (user.role) {
      case 'STUDENT': return AppColors.primary;
      case 'GUARD':   return AppColors.warning;
      case 'ADMIN':   return AppColors.error;
      default:        return AppColors.textSecondary;
    }
  }

  String _roleLabel() {
    switch (user.role) {
      case 'STUDENT': return 'Student';
      case 'GUARD':   return 'Guard';
      case 'ADMIN':   return 'Admin';
      default:        return user.role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:        AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width:  44,
              height: 44,
              decoration: BoxDecoration(
                color:  color.withValues(alpha: 0.20),
                shape:  BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user.fullName.isNotEmpty
                      ? user.fullName[0].toUpperCase()
                      : '?',
                  style: AppTypography.labelLarge.copyWith(color: color),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name + role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName,
                      style: AppTypography.bodyLarge,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Role pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:        color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _roleLabel(),
                          style: AppTypography.labelSmall
                              .copyWith(color: color, fontSize: 10),
                        ),
                      ),
                      if (user.studentId != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          user.studentId!,
                          style: AppTypography.bodySmall.copyWith(
                              fontFamily: 'JetBrains Mono'),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Status dot + label
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width:  8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: user.isActive
                        ? AppColors.success
                        : AppColors.textTertiary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.isActive ? 'Active' : 'Inactive',
                  style: AppTypography.bodySmall.copyWith(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
