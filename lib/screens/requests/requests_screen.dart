import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme_ext.dart';
import '../../providers/job_notifier.dart';
import '../../providers/locale_provider.dart';
import '../../models/job_status.dart';
import '../../models/mechanic_offer.dart';
import '../../models/job.dart';
import '../request_flow/request_creation_flow.dart';

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobState = ref.watch(jobProvider);

    if (!jobState.hasActiveJob) {
      return _EmptyView(onNewRequest: () => openRequestFlow(context));
    }

    final canCancel =
        jobState.customerStatus == CustomerRequestStatus.searching ||
        jobState.customerStatus == CustomerRequestStatus.mechanicsResponding ||
        jobState.customerStatus == CustomerRequestStatus.enRoute;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Request'),
        actions: [
          if (canCancel)
            TextButton(
              onPressed: () => ref.read(jobProvider.notifier).cancelRequest(),
              child: const Text('Cancel',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: Column(
        children: [
          _StatusBanner(status: jobState.customerStatus),
          Expanded(child: _buildBody(context, ref, jobState)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, JobState state) {
    final notifier = ref.read(jobProvider.notifier);

    switch (state.customerStatus) {
      case CustomerRequestStatus.searching:
        return _SearchingView(job: state.activeJob);

      case CustomerRequestStatus.mechanicsResponding:
        return _OffersView(
          offers: state.pendingOffers,
          onSelect: (o) => notifier.selectMechanic(o),
        );

      case CustomerRequestStatus.mechanicSelected:
        return _ConfirmingView(job: state.activeJob);

      case CustomerRequestStatus.enRoute:
        return _EnRouteView(job: state.activeJob);

      case CustomerRequestStatus.inspectionActive:
        return _InspectionActiveView(job: state.activeJob);

      case CustomerRequestStatus.quoteReceived:
        return _QuoteReceivedView(
          job: state.activeJob,
          jobState: state,
          onApprove: () => notifier.customerApprovesQuote(),
          onReject: () => notifier.customerRejectsQuote(),
        );

      case CustomerRequestStatus.awaitingRevision:
        return _AwaitingRevisionView(job: state.activeJob);

      case CustomerRequestStatus.repairInProgress:
        return _RepairInProgressView(job: state.activeJob);

      case CustomerRequestStatus.completionVerification:
        return _CompletionVerificationView(
          job: state.activeJob,
          jobState: state,
          onConfirm: () => notifier.customerConfirmsCompletion(),
          onDispute: () => notifier.customerDisputesRepair(),
        );

      case CustomerRequestStatus.paymentPending:
        return _PaymentPendingView(
          job: state.activeJob,
          amount: state.generatedQuote ?? 0,
        );

      case CustomerRequestStatus.awaitingReview:
        return _ReviewView(
          job: state.activeJob,
          onSubmit: (stars, resolved, professional, comment) =>
              notifier.submitReview(
                stars: stars,
                issueResolved: resolved,
                wasProfessional: professional,
                comment: comment,
              ),
          onSkip: () => notifier.skipReview(),
        );

      case CustomerRequestStatus.completed:
      case CustomerRequestStatus.cancelled:
      case CustomerRequestStatus.disputed:
        return _DoneView(
          state: state,
          onReset: () => notifier.reset(),
        );

      default:
        return const SizedBox();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status banner
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status});
  final CustomerRequestStatus status;

  Color get _color {
    switch (status) {
      case CustomerRequestStatus.searching:
      case CustomerRequestStatus.mechanicsResponding:
        return AppColors.warning;
      case CustomerRequestStatus.mechanicSelected:
      case CustomerRequestStatus.enRoute:
        return AppColors.primary;
      case CustomerRequestStatus.inspectionActive:
      case CustomerRequestStatus.awaitingRevision:
        return const Color(0xFF6366F1);
      case CustomerRequestStatus.quoteReceived:
        return AppColors.warning;
      case CustomerRequestStatus.repairInProgress:
        return AppColors.primary;
      case CustomerRequestStatus.completionVerification:
        return const Color(0xFF6366F1);
      case CustomerRequestStatus.paymentPending:
        return AppColors.success;
      case CustomerRequestStatus.awaitingReview:
      case CustomerRequestStatus.completed:
        return AppColors.success;
      case CustomerRequestStatus.disputed:
        return AppColors.error;
      default:
        return AppColors.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _color.withValues(alpha: 0.1),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: _color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(
            status.displayLabel,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600, color: _color),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / new request
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onNewRequest});
  final VoidCallback onNewRequest;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Requests')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                  color: AppColors.primarySurface, shape: BoxShape.circle),
              child: const Icon(Icons.pending_actions_rounded,
                  size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text('No active requests',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Need a mechanic? Describe your problem and we\'ll find the right person nearby.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: AppColors.textGrey, height: 1.5),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onNewRequest,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Request',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Searching
// ─────────────────────────────────────────────────────────────────────────────

class _SearchingView extends StatelessWidget {
  const _SearchingView({required this.job});
  final Job? job;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _JobSummaryCard(job: job),
        const SizedBox(height: 24),
        const Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text('Finding nearby mechanics…',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
              SizedBox(height: 6),
              Text('Ranking by skill match, rating & distance',
                  style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mechanics responding — customer picks one
// ─────────────────────────────────────────────────────────────────────────────

class _OffersView extends StatelessWidget {
  const _OffersView({required this.offers, required this.onSelect});
  final List<MechanicOffer> offers;
  final ValueChanged<MechanicOffer> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('${offers.length} mechanics responding',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
        const SizedBox(height: 4),
        const Text('Ranked by skill match · rating · distance',
            style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
        const SizedBox(height: 16),
        ...offers.map((o) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OfferCard(offer: o, onSelect: () => onSelect(o)),
            )),
      ],
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer, required this.onSelect});
  final MechanicOffer offer;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
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
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primarySurface,
                child: Text(offer.name[0],
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.warning, size: 14),
                        const SizedBox(width: 3),
                        Text('${offer.rating}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textGrey)),
                        Text(' · ${offer.reviewCount} reviews',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textGrey)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('KES ${offer.priceEstimate}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const Text('est.',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textGrey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoPill(
                  icon: Icons.near_me_rounded,
                  label: '${offer.distanceKm} km'),
              const SizedBox(width: 8),
              _InfoPill(
                  icon: Icons.access_time_rounded,
                  label: '${offer.etaMinutes} min'),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: offer.skills
                .take(3)
                .map((s) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(s,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary)),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSelect,
              child: const Text('Select Mechanic'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textGrey),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirming (mechanic acceptance window)
// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmingView extends StatelessWidget {
  const _ConfirmingView({required this.job});
  final Job? job;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AssignedMechanicCard(job: job),
        const SizedBox(height: 20),
        const Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 12),
              Text('Waiting for mechanic to confirm…',
                  style: TextStyle(fontSize: 14, color: AppColors.textGrey)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// En Route — live GPS + call / chat / cancel
// ─────────────────────────────────────────────────────────────────────────────

class _EnRouteView extends ConsumerStatefulWidget {
  const _EnRouteView({required this.job});
  final Job? job;

  @override
  ConsumerState<_EnRouteView> createState() => _EnRouteViewState();
}

class _EnRouteViewState extends ConsumerState<_EnRouteView> {
  double? _customerLat;
  double? _customerLng;
  String? _locationError;
  bool _locationLoading = true;

  double _mechLat = -1.3100;
  double _mechLng = 36.8400;

  Timer? _timer;
  int _etaSeconds = 0;

  @override
  void initState() {
    super.initState();
    _etaSeconds = (widget.job?.assignedOffer?.etaMinutes ?? 10) * 60;
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _locationError = 'GPS disabled — enable location services.';
            _locationLoading = false;
          });
        }
        return;
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationError = 'Location permission denied.';
            _locationLoading = false;
          });
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) return;
      setState(() {
        _customerLat = pos.latitude;
        _customerLng = pos.longitude;
        _mechLat = pos.latitude - 0.025;
        _mechLng = pos.longitude + 0.015;
        _locationLoading = false;
      });
      _startTracking();
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'Location unavailable.';
          _locationLoading = false;
        });
      }
    }
  }

  void _startTracking() {
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() {
        if (_customerLat != null && _customerLng != null) {
          final dLat = _customerLat! - _mechLat;
          final dLng = _customerLng! - _mechLng;
          final dist = sqrt(dLat * dLat + dLng * dLng);
          const step = 0.00022;
          if (dist > step) {
            _mechLat += (dLat / dist) * step;
            _mechLng += (dLng / dist) * step;
          }
        }
        if (_etaSeconds > 2) _etaSeconds -= 2;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _distanceKm {
    if (_customerLat == null || _customerLng == null) return 0;
    return Geolocator.distanceBetween(
            _mechLat, _mechLng, _customerLat!, _customerLng!) /
        1000;
  }

  String get _etaLabel {
    final mins = (_etaSeconds / 60).ceil();
    return mins > 0 ? '$mins min' : 'Arriving';
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(localeProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AssignedMechanicCard(job: widget.job),
        const SizedBox(height: 16),

        // Action buttons: call, chat, cancel (before arrival)
        Row(
          children: [
            Expanded(
              child: _ActionChip(
                icon: Icons.phone_rounded,
                label: 'Call',
                color: AppColors.success,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionChip(
                icon: Icons.chat_bubble_rounded,
                label: 'Chat',
                color: AppColors.primary,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ActionChip(
                icon: Icons.close_rounded,
                label: 'Cancel',
                color: AppColors.error,
                onTap: () => ref.read(jobProvider.notifier).cancelRequest(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _LiveTrackingCard(
          lang: lang,
          locationLoading: _locationLoading,
          locationError: _locationError,
          customerLat: _customerLat,
          customerLng: _customerLng,
          mechLat: _mechLat,
          mechLng: _mechLng,
          distanceKm: _distanceKm,
          etaLabel: _etaLabel,
          etaMinutes: widget.job?.assignedOffer?.etaMinutes ?? 10,
          etaSecondsRemaining: _etaSeconds,
        ),
        const SizedBox(height: 16),
        _UpdatesTimeline(updates: widget.job?.updates ?? []),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

class _LiveTrackingCard extends StatelessWidget {
  const _LiveTrackingCard({
    required this.lang,
    required this.locationLoading,
    required this.locationError,
    required this.customerLat,
    required this.customerLng,
    required this.mechLat,
    required this.mechLng,
    required this.distanceKm,
    required this.etaLabel,
    required this.etaMinutes,
    required this.etaSecondsRemaining,
  });

  final String lang;
  final bool locationLoading;
  final String? locationError;
  final double? customerLat;
  final double? customerLng;
  final double mechLat;
  final double mechLng;
  final double distanceKm;
  final String etaLabel;
  final int etaMinutes;
  final int etaSecondsRemaining;

  double get _progress {
    if (customerLat == null) return 0;
    final totalSeconds = etaMinutes * 60;
    final elapsed = totalSeconds - etaSecondsRemaining;
    return (elapsed / totalSeconds).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.gps_fixed_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(t('live_tracking', lang),
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.textDark)),
              const Spacer(),
              if (!locationLoading && locationError == null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                      const Text('LIVE',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.success)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (locationLoading)
            Row(
              children: [
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary)),
                const SizedBox(width: 10),
                Text('Acquiring GPS location…',
                    style:
                        TextStyle(fontSize: 13, color: context.textGrey)),
              ],
            )
          else if (locationError != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_off_rounded,
                      color: AppColors.warning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(locationError!,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.warning))),
                ],
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _TrackingMetric(
                    label: t('eta', lang),
                    value: etaLabel,
                    icon: Icons.access_time_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TrackingMetric(
                    label: t('distance', lang),
                    value: '${distanceKm.toStringAsFixed(2)} km',
                    icon: Icons.straighten_rounded,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Map placeholder (Google Maps would be embedded here)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_rounded,
                        color: AppColors.primary, size: 28),
                    SizedBox(height: 6),
                    Text('Live map view',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.primary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Journey progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t('mechanic_location', lang),
                        style: TextStyle(
                            fontSize: 11, color: context.textGrey)),
                    Text(t('your_location', lang),
                        style: TextStyle(
                            fontSize: 11, color: context.textGrey)),
                  ],
                ),
                const SizedBox(height: 6),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: context.divider,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: _progress,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.success],
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TrackingMetric extends StatelessWidget {
  const _TrackingMetric({
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      TextStyle(fontSize: 10, color: context.textGrey)),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.textDark)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inspection Active — mechanic inspecting, customer waits
// ─────────────────────────────────────────────────────────────────────────────

class _InspectionActiveView extends StatelessWidget {
  const _InspectionActiveView({required this.job});
  final Job? job;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AssignedMechanicCard(job: job),
        const SizedBox(height: 16),
        _StageInfoCard(
          icon: Icons.search_rounded,
          color: const Color(0xFF6366F1),
          title: 'Mechanic is inspecting your vehicle',
          subtitle:
              'They\'re physically checking the issue and documenting findings. You\'ll receive a quote once diagnosis is complete.',
        ),
        const SizedBox(height: 16),
        _UpdatesTimeline(updates: job?.updates ?? []),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quote Received — customer reviews diagnosis + quote
// ─────────────────────────────────────────────────────────────────────────────

class _QuoteReceivedView extends StatelessWidget {
  const _QuoteReceivedView({
    required this.job,
    required this.jobState,
    required this.onApprove,
    required this.onReject,
  });

  final Job? job;
  final JobState jobState;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final quote = jobState.generatedQuote ?? 0;
    final notes = jobState.diagnosisNotes ?? '';
    final complexity = jobState.repairComplexity ?? 'moderate';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AssignedMechanicCard(job: job),
        const SizedBox(height: 16),

        // Diagnosis summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DIAGNOSIS',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                      letterSpacing: 0.8)),
              const SizedBox(height: 10),
              Text(
                notes.isEmpty
                    ? 'Mechanic has completed the inspection.'
                    : notes,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textDark, height: 1.5),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _complexityColor(complexity).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_capitalise(complexity)} repair',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _complexityColor(complexity)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Evidence (placeholder)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('No photos uploaded by mechanic',
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textGrey)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Repair quote
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('REPAIR QUOTE',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textGrey,
                      letterSpacing: 0.8)),
              const SizedBox(height: 12),
              _QuoteRow(
                  label: 'Labour',
                  value: 'KES ${(quote * 0.6).toStringAsFixed(0)}'),
              const SizedBox(height: 6),
              _QuoteRow(
                  label: 'Parts (est.)',
                  value: 'KES ${(quote * 0.4).toStringAsFixed(0)}'),
              const SizedBox(height: 10),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  Text('KES ${quote.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.schedule_rounded,
                      size: 14, color: AppColors.textGrey),
                  const SizedBox(width: 6),
                  Text(
                    'Est. completion: ${job?.minimumServiceMinutes ?? 60} min',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textGrey),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Approve
        ElevatedButton(
          onPressed: onApprove,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size.fromHeight(52)),
          child: const Text('Approve Quote'),
        ),
        const SizedBox(height: 10),

        // Reject
        OutlinedButton(
          onPressed: onReject,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Reject Quote'),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Rejecting will ask the mechanic to revise the diagnosis.\nYou may also end the session and pay only the inspection fee.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: AppColors.textGrey, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        _UpdatesTimeline(updates: job?.updates ?? []),
      ],
    );
  }

  Color _complexityColor(String c) {
    switch (c.toLowerCase()) {
      case 'minor':
        return AppColors.success;
      case 'major':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _capitalise(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _QuoteRow extends StatelessWidget {
  const _QuoteRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textGrey)),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Awaiting Revision — customer rejected, mechanic revising
// ─────────────────────────────────────────────────────────────────────────────

class _AwaitingRevisionView extends StatelessWidget {
  const _AwaitingRevisionView({required this.job});
  final Job? job;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AssignedMechanicCard(job: job),
        const SizedBox(height: 16),
        _StageInfoCard(
          icon: Icons.edit_note_rounded,
          color: const Color(0xFF6366F1),
          title: 'Mechanic is revising the diagnosis',
          subtitle:
              'You rejected the initial quote. The mechanic will submit a revised diagnosis and updated pricing.',
        ),
        const SizedBox(height: 16),
        _UpdatesTimeline(updates: job?.updates ?? []),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Repair In Progress — customer sees updates as mechanic works
// ─────────────────────────────────────────────────────────────────────────────

class _RepairInProgressView extends StatelessWidget {
  const _RepairInProgressView({required this.job});
  final Job? job;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AssignedMechanicCard(job: job),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.build_rounded,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Repair in progress',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark)),
                    Text(
                      'Est. time: ${job?.minimumServiceMinutes ?? 60} min',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _StageInfoCard(
          icon: Icons.info_outline_rounded,
          color: AppColors.textGrey,
          title: 'If a new issue is found',
          subtitle:
              'The mechanic will submit a revised diagnosis and updated quote for your approval before any additional work begins.',
        ),
        const SizedBox(height: 16),
        _UpdatesTimeline(updates: job?.updates ?? []),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Completion Verification — check vehicle, confirm or dispute
// ─────────────────────────────────────────────────────────────────────────────

class _CompletionVerificationView extends StatelessWidget {
  const _CompletionVerificationView({
    required this.job,
    required this.jobState,
    required this.onConfirm,
    required this.onDispute,
  });

  final Job? job;
  final JobState jobState;
  final VoidCallback onConfirm;
  final VoidCallback onDispute;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AssignedMechanicCard(job: job),
        const SizedBox(height: 16),
        _StageInfoCard(
          icon: Icons.verified_rounded,
          color: AppColors.success,
          title: 'Mechanic says the repair is done',
          subtitle:
              'Check your vehicle before confirming. Auto-confirmed after 10 minutes if no response.',
        ),
        const SizedBox(height: 16),

        // What to check
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Before you confirm',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark)),
              const SizedBox(height: 10),
              ...[
                'Start the vehicle and check for warning lights',
                'Test the repaired system (e.g., brakes, AC, engine)',
                'Confirm no new sounds or issues',
              ].map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 4, right: 8),
                          child: Icon(Icons.check_circle_outline_rounded,
                              color: AppColors.success, size: 16),
                        ),
                        Expanded(
                          child: Text(item,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textGrey,
                                  height: 1.4)),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Confirm — triggers M-Pesa
        ElevatedButton.icon(
          onPressed: onConfirm,
          icon: const Icon(Icons.check_circle_rounded),
          label: const Text('Yes, issue is resolved'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            minimumSize: const Size.fromHeight(52),
          ),
        ),
        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: onDispute,
          icon: const Icon(Icons.report_outlined),
          label: const Text('Issue not resolved — raise dispute'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            side: const BorderSide(color: AppColors.error),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        const SizedBox(height: 16),
        _UpdatesTimeline(updates: job?.updates ?? []),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment Pending — M-Pesa STK push
// ─────────────────────────────────────────────────────────────────────────────

class _PaymentPendingView extends StatelessWidget {
  const _PaymentPendingView({required this.job, required this.amount});
  final Job? job;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_android_rounded,
                  size: 48, color: AppColors.success),
            ),
            const SizedBox(height: 20),
            const Text('M-Pesa Payment Sent',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(
              'Check your phone for the STK push prompt.\nEnter your M-Pesa PIN to complete payment.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textGrey, height: 1.5),
            ),
            if (amount > 0) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'KES ${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  color: AppColors.success, strokeWidth: 2.5),
            ),
            const SizedBox(height: 10),
            const Text('Processing…',
                style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Review
// ─────────────────────────────────────────────────────────────────────────────

class _ReviewView extends StatefulWidget {
  const _ReviewView(
      {required this.job, required this.onSubmit, required this.onSkip});
  final Job? job;
  final void Function(
          int stars, bool resolved, bool professional, String? comment)
      onSubmit;
  final VoidCallback onSkip;

  @override
  State<_ReviewView> createState() => _ReviewViewState();
}

class _ReviewViewState extends State<_ReviewView> {
  int _stars = 0;
  bool? _issueResolved;
  bool? _wasProfessional;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        _stars > 0 && _issueResolved != null && _wasProfessional != null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Rate your experience',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark)),
        const SizedBox(height: 4),
        const Text('Takes less than 30 seconds',
            style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (i) => GestureDetector(
              onTap: () => setState(() => _stars = i + 1),
              child: Icon(
                i < _stars
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: AppColors.warning,
                size: 40,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _QuickTap(
          label: 'Issue resolved?',
          value: _issueResolved,
          onChanged: (v) => setState(() => _issueResolved = v),
        ),
        const SizedBox(height: 12),
        _QuickTap(
          label: 'Mechanic was professional?',
          value: _wasProfessional,
          onChanged: (v) => setState(() => _wasProfessional = v),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _commentController,
          decoration: const InputDecoration(hintText: 'Optional comment…'),
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: canSubmit
              ? () => widget.onSubmit(
                    _stars,
                    _issueResolved!,
                    _wasProfessional!,
                    _commentController.text.isEmpty
                        ? null
                        : _commentController.text,
                  )
              : null,
          child: const Text('Submit Review'),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: widget.onSkip,
            child: const Text('Skip',
                style: TextStyle(color: AppColors.textGrey)),
          ),
        ),
      ],
    );
  }
}

class _QuickTap extends StatelessWidget {
  const _QuickTap(
      {required this.label, required this.value, required this.onChanged});
  final String label;
  final bool? value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textDark))),
        _TapChip(
            label: 'YES',
            selected: value == true,
            onTap: () => onChanged(true)),
        const SizedBox(width: 8),
        _TapChip(
            label: 'NO',
            selected: value == false,
            onTap: () => onChanged(false)),
      ],
    );
  }
}

class _TapChip extends StatelessWidget {
  const _TapChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : AppColors.textGrey),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Done (completed / cancelled / disputed)
// ─────────────────────────────────────────────────────────────────────────────

class _DoneView extends StatelessWidget {
  const _DoneView({required this.state, required this.onReset});
  final JobState state;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final isDone = state.customerStatus == CustomerRequestStatus.completed;
    final isDisputed =
        state.customerStatus == CustomerRequestStatus.disputed;

    final icon = isDone
        ? Icons.check_circle_rounded
        : isDisputed
            ? Icons.gavel_rounded
            : Icons.cancel_rounded;
    final color = isDone
        ? AppColors.success
        : isDisputed
            ? AppColors.error
            : AppColors.error;
    final title = isDone
        ? 'Repair Complete!'
        : isDisputed
            ? 'Dispute Submitted'
            : 'Request Cancelled';
    final subtitle = isDone
        ? 'Payment processed and repair record saved.'
        : isDisputed
            ? 'Our team is reviewing the evidence. Payment is on hold until resolved.'
            : 'Your request was cancelled.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: color),
            ),
            const SizedBox(height: 20),
            Text(title,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textGrey, height: 1.5)),
            if (isDone && state.activeJob?.review != null) ...[
              const SizedBox(height: 8),
              Text(
                '${state.activeJob!.review!.stars} ★ · Thank you for your review',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textGrey),
              ),
            ],
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: onReset,
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _JobSummaryCard extends StatelessWidget {
  const _JobSummaryCard({required this.job});
  final Job? job;

  @override
  Widget build(BuildContext context) {
    if (job == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(job!.serviceCategory,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ),
              const SizedBox(width: 8),
              Text(job!.carType,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textGrey)),
            ],
          ),
          const SizedBox(height: 8),
          Text(job!.problemDescription,
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textDark, height: 1.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 14, color: AppColors.textGrey),
              const SizedBox(width: 4),
              Text(job!.location,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textGrey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssignedMechanicCard extends StatelessWidget {
  const _AssignedMechanicCard({required this.job});
  final Job? job;

  @override
  Widget build(BuildContext context) {
    final offer = job?.assignedOffer;
    if (offer == null) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primarySurface,
            child: Text(offer.name[0],
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: AppColors.warning, size: 13),
                    const SizedBox(width: 3),
                    Text('${offer.rating} · ${offer.reviewCount} reviews',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textGrey)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${offer.etaMinutes} min',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              const Text('ETA',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textGrey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageInfoCard extends StatelessWidget {
  const _StageInfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpdatesTimeline extends StatelessWidget {
  const _UpdatesTimeline({required this.updates});
  final List<JobUpdate> updates;

  @override
  Widget build(BuildContext context) {
    if (updates.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activity',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
        const SizedBox(height: 8),
        ...updates.reversed.take(6).map(
              (u) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5, right: 8),
                      child: CircleAvatar(
                          radius: 3,
                          backgroundColor: AppColors.primary),
                    ),
                    Expanded(
                      child: Text(u.message,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textGrey)),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
