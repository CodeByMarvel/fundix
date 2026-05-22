import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../services/request_service.dart';

final _historyProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final all = await RequestService.fetchRequests();
  // History = finished jobs only. Active/pending requests live on the Requests tab.
  return all
      .where((r) => r['status'] == 'completed' || r['status'] == 'cancelled')
      .toList();
});

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(_historyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Service History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(_historyProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(_historyProvider),
        ),
        data: (records) {
          final filtered = switch (_tabs.index) {
            1 => records.where((r) => r['status'] == 'completed').toList(),
            2 => records.where((r) => r['status'] == 'cancelled').toList(),
            _ => records,
          };

          return filtered.isEmpty
              ? _EmptyState(tab: _tabs.index)
              : _RecordList(records: filtered);
        },
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.tab});
  final int tab;

  @override
  Widget build(BuildContext context) {
    final label = tab == 2 ? 'No cancelled requests' : 'No service records yet';
    final sub = tab == 2
        ? 'Any cancelled requests will appear here.'
        : 'Completed jobs will appear here — including receipts, diagnosis summaries, and mechanic details.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_rounded,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(label,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(sub,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textGrey, height: 1.5)),
          ],
        ),
      ),
    );
  }
}

// ── Error state ────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.textGrey),
            const SizedBox(height: 16),
            const Text('Could not load history',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

// ── List ───────────────────────────────────────────────────────────────────────

class _RecordList extends StatelessWidget {
  const _RecordList({required this.records});
  final List<Map<String, dynamic>> records;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: records.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ServiceRecordCard(record: records[i]),
    );
  }
}

// ── Service record card ────────────────────────────────────────────────────────

class _ServiceRecordCard extends StatelessWidget {
  const _ServiceRecordCard({required this.record});
  final Map<String, dynamic> record;

  @override
  Widget build(BuildContext context) {
    final status = record['status'] as String? ?? 'completed';
    final isCompleted = status == 'completed';

    final vehicleInfo = record['vehicle_info'] as Map<String, dynamic>?;
    final vehicleName = vehicleInfo?['displayName'] as String?
        ?? vehicleInfo?['brand'] as String?
        ?? 'Vehicle';

    final symptoms = record['symptoms'] as String? ?? '—';
    final priceRaw = record['price_estimate'];
    final price = priceRaw != null
        ? 'KES ${(priceRaw as num).toStringAsFixed(0)}'
        : null;

    final diagnosisRaw = record['diagnosis_result'] as Map<String, dynamic>?;
    final diagnosisSummary = diagnosisRaw?['summary'] as String?
        ?? diagnosisRaw?['diagnosis'] as String?;

    final createdAt = record['created_at'] as String?;
    final date = createdAt != null
        ? _formatDate(DateTime.tryParse(createdAt))
        : '—';

    final statusColor = isCompleted ? AppColors.success : AppColors.error;
    final statusLabel = isCompleted ? 'Completed' : 'Cancelled';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: vehicle name + status badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.directions_car_rounded,
                    size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(vehicleName,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark),
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(statusLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Symptoms
          Text('Reported issue',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textGrey,
                  letterSpacing: 0.4)),
          const SizedBox(height: 3),
          Text(symptoms,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textDark, height: 1.4)),

          // Diagnosis summary (if available)
          if (diagnosisSummary != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(diagnosisSummary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            height: 1.4)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(color: AppColors.divider, height: 1),
          const SizedBox(height: 10),

          // Footer: date + price
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 12, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Text(date,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textGrey)),
              const Spacer(),
              if (price != null && isCompleted) ...[
                const Icon(Icons.payments_outlined,
                    size: 13, color: AppColors.success),
                const SizedBox(width: 4),
                Text(price,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
