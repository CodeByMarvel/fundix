import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme_ext.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/job_notifier.dart';
import '../../../providers/locale_provider.dart';
import '../../../models/job_status.dart';
import '../../../providers/earnings_provider.dart';
import '../../../providers/mechanic_availability_provider.dart';
import '../../../services/mechanic_api_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../jobs/jobs_screen.dart';
import '../earnings/earnings_screen.dart';
import '../profile/mechanic_profile_screen.dart';

final _mechanicStatusProvider = FutureProvider<String>((ref) async {
  final profile = await MechanicApiService.getProfile();
  return profile['application_status'] as String? ?? 'pending';
});

class MechanicShell extends ConsumerStatefulWidget {
  const MechanicShell({super.key});

  @override
  ConsumerState<MechanicShell> createState() => _MechanicShellState();
}

class _MechanicShellState extends ConsumerState<MechanicShell> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    DashboardScreen(),
    JobsScreen(),
    EarningsScreen(),
    MechanicProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    ref.read(mechanicShellIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(_mechanicStatusProvider);

    // Gate on application status before rendering the full shell
    return statusAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => _StatusScreen(
        icon: Icons.wifi_off_rounded,
        title: 'Could not load profile',
        subtitle: 'Check your connection and try again.',
        onRetry: () => ref.invalidate(_mechanicStatusProvider),
      ),
      data: (status) {
        if (status == 'pending') {
          return _StatusScreen(
            icon: Icons.hourglass_top_rounded,
            title: 'Application Under Review',
            subtitle:
                'We\'re reviewing your profile. This usually takes 24–48 hours. You\'ll be notified once approved.',
            onRetry: () => ref.invalidate(_mechanicStatusProvider),
            retryLabel: 'Check Again',
            onSignOut: () => ref.read(authProvider.notifier).signOut(),
          );
        }
        if (status == 'rejected') {
          return _StatusScreen(
            icon: Icons.cancel_outlined,
            iconColor: AppColors.error,
            title: 'Application Not Approved',
            subtitle:
                'Your application didn\'t meet our current requirements. Contact support at support@fundi-x.co.ke if you believe this is an error.',
            onSignOut: () => ref.read(authProvider.notifier).signOut(),
          );
        }

        // status == 'approved' — normal shell
        ref.listen<int>(mechanicShellIndexProvider, (_, next) {
          if (_currentIndex != next) setState(() => _currentIndex = next);
        });

        ref.listen<JobState>(jobProvider, (previous, next) {
          if (previous?.mechanicJobStatus == MechanicJobStatus.idle &&
              next.mechanicJobStatus == MechanicJobStatus.received) {
            setState(() => _currentIndex = 1);
          }
          if (previous?.customerStatus == CustomerRequestStatus.paymentPending &&
              next.customerStatus == CustomerRequestStatus.awaitingReview) {
            final amount = next.generatedQuote;
            final category = next.activeJob?.serviceCategory;
            if (amount != null && category != null) {
              ref.read(earningsProvider.notifier).recordJob(
                amount: amount,
                category: category,
              );
            }
          }
        });

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          bottomNavigationBar: _MechanicNavBar(
            currentIndex: _currentIndex,
            onTap: _onTabTapped,
          ),
        );
      },
    );
  }
}

class _MechanicNavBar extends ConsumerWidget {
  const _MechanicNavBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    final items = [
      _NavItemData(icon: Icons.dashboard_rounded, label: t('dashboard', lang)),
      _NavItemData(icon: Icons.handyman_rounded, label: t('jobs', lang)),
      _NavItemData(icon: Icons.account_balance_wallet_rounded, label: t('earnings', lang)),
      _NavItemData(icon: Icons.person_rounded, label: t('profile', lang)),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Container(
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: context.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: context.isDark ? 0.3 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
              (i) => _NavItem(
                data: items[i],
                isSelected: i == currentIndex,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItemData data;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                data.icon,
                key: ValueKey(isSelected),
                size: 24,
                color: isSelected ? AppColors.primary : context.inactive,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : context.inactive,
                letterSpacing: 0.1,
              ),
              child: Text(data.label),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Application status gate screen ────────────────────────────────────────────

class _StatusScreen extends StatelessWidget {
  const _StatusScreen({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconColor,
    this.onRetry,
    this.retryLabel,
    this.onSignOut,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;
  final String? retryLabel;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 52, color: color),
              ),
              const SizedBox(height: 28),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              if (onRetry != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(retryLabel ?? 'Retry'),
                  ),
                ),
              if (onSignOut != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onSignOut,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textGrey,
                      side: const BorderSide(color: AppColors.divider),
                    ),
                    child: const Text('Sign Out'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
