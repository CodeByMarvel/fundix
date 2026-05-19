import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/earnings_provider.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  int _selectedPeriod = 0;
  static const _periods = ['Today', 'This Week', 'This Month'];

  @override
  Widget build(BuildContext context) {
    final earnings = ref.watch(earningsProvider);

    final txs = switch (_selectedPeriod) {
      0 => earnings.today,
      1 => earnings.thisWeek,
      _ => earnings.thisMonth,
    };

    final total = earnings.totalFor(txs);
    final jobCount = txs.length;
    final avgLabel = jobCount == 0 ? '—' : _kes(total / jobCount);
    final bestDayLabel = _bestDay(txs);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Earnings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          _PeriodSelector(
            selected: _selectedPeriod,
            periods: _periods,
            onSelect: (i) => setState(() => _selectedPeriod = i),
          ),
          const SizedBox(height: 16),
          _EarningsSummaryCard(
            period: _periods[_selectedPeriod],
            totalLabel: _kes(total),
            jobCount: jobCount,
            hoursLabel: _formatHours(jobCount * 45),
          ),
          const SizedBox(height: 20),
          _BreakdownSection(avgPerJob: avgLabel, bestDay: bestDayLabel ?? '—'),
          const SizedBox(height: 20),
          _TransactionList(transactions: txs.reversed.toList()),
        ],
      ),
    );
  }

  String _kes(double amount) {
    final n = amount.round();
    if (n >= 1000) {
      return 'KES ${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return 'KES $n';
  }

  String _formatHours(int minutes) {
    if (minutes == 0) return '0h';
    if (minutes % 60 == 0) return '${minutes ~/ 60}h';
    return '${minutes ~/ 60}h ${minutes % 60}m';
  }

  String? _bestDay(List<EarningsTransaction> txs) {
    if (txs.isEmpty) return null;
    final byDay = <int, double>{};
    for (final t in txs) {
      final wd = t.completedAt.weekday;
      byDay[wd] = (byDay[wd] ?? 0) + t.amount;
    }
    final best = byDay.entries.reduce((a, b) => a.value > b.value ? a : b);
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[best.key - 1];
  }
}

// ── Period selector ───────────────────────────────────────────────────────────

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.periods,
    required this.onSelect,
  });

  final int selected;
  final List<String> periods;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(periods.length, (i) {
        final isSelected = i == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < periods.length - 1 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Text(
                periods[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : AppColors.textGrey,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _EarningsSummaryCard extends StatelessWidget {
  const _EarningsSummaryCard({
    required this.period,
    required this.totalLabel,
    required this.jobCount,
    required this.hoursLabel,
  });

  final String period;
  final String totalLabel;
  final int jobCount;
  final String hoursLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            period,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            totalLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryPill(
                label: '$jobCount ${jobCount == 1 ? 'job' : 'jobs'}',
                icon: Icons.handyman_rounded,
              ),
              const SizedBox(width: 10),
              _SummaryPill(
                label: '$hoursLabel worked',
                icon: Icons.access_time_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Breakdown cards ───────────────────────────────────────────────────────────

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({required this.avgPerJob, required this.bestDay});

  final String avgPerJob;
  final String bestDay;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _BreakdownCard(
            label: 'Avg per Job',
            value: avgPerJob,
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _BreakdownCard(
            label: 'Best Day',
            value: bestDay,
            icon: Icons.emoji_events_rounded,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Transaction list ──────────────────────────────────────────────────────────

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.transactions});
  final List<EarningsTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transactions',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Center(
              child: Text(
                'No transactions yet',
                style: TextStyle(fontSize: 14, color: AppColors.textGrey),
              ),
            ),
          )
        else
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < transactions.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: AppColors.divider,
                      ),
                    _TransactionTile(tx: transactions[i]),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});
  final EarningsTransaction tx;

  String get _timeLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(
        tx.completedAt.year, tx.completedAt.month, tx.completedAt.day);
    final diff = today.difference(txDay).inDays;
    final h = tx.completedAt.hour.toString().padLeft(2, '0');
    final m = tx.completedAt.minute.toString().padLeft(2, '0');
    final time = '$h:$m';
    if (diff == 0) return 'Today · $time';
    if (diff == 1) return 'Yesterday · $time';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[tx.completedAt.weekday - 1]} · $time';
  }

  IconData get _icon {
    switch (tx.category.toLowerCase()) {
      case 'engine':
        return Icons.settings_rounded;
      case 'brake':
        return Icons.disc_full_rounded;
      case 'tire':
        return Icons.tire_repair_rounded;
      case 'electrical':
        return Icons.bolt_rounded;
      case 'battery':
        return Icons.battery_charging_full_rounded;
      default:
        return Icons.build_rounded;
    }
  }

  String _kes(double amount) {
    final n = amount.round();
    if (n >= 1000) {
      return 'KES ${n ~/ 1000},${(n % 1000).toString().padLeft(3, '0')}';
    }
    return 'KES $n';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _timeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '+${_kes(tx.amount)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
