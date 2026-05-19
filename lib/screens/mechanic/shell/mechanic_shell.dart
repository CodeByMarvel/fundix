import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme_ext.dart';
import '../../../providers/job_notifier.dart';
import '../../../providers/locale_provider.dart';
import '../../../models/job_status.dart';
import '../../../providers/earnings_provider.dart';
import '../../../providers/mechanic_availability_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../jobs/jobs_screen.dart';
import '../earnings/earnings_screen.dart';
import '../profile/mechanic_profile_screen.dart';

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
    ref.listen<int>(mechanicShellIndexProvider, (_, next) {
      if (_currentIndex != next) setState(() => _currentIndex = next);
    });

    ref.listen<JobState>(jobProvider, (previous, next) {
      if (previous?.mechanicJobStatus == MechanicJobStatus.idle &&
          next.mechanicJobStatus == MechanicJobStatus.received) {
        setState(() => _currentIndex = 1);
      }
      // Record earnings when M-Pesa payment clears
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
