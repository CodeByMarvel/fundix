import 'package:flutter/material.dart';
import '../../../models/mechanic_offer.dart';
import '../../../models/mechanic_type.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme_ext.dart';

// ── Entry point ────────────────────────────────────────────────────────────────
// Call this from any screen to show a mechanic's trust card as a bottom sheet.

void showMechanicProfile(
  BuildContext context, {
  required MechanicOffer offer,
  required MechanicType type,
  // Called when customer confirms they want THIS mechanic
  required VoidCallback onSelect,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _MechanicProfileSheet(offer: offer, type: type, onSelect: onSelect),
  );
}

// ── Sheet wrapper ──────────────────────────────────────────────────────────────

class _MechanicProfileSheet extends StatelessWidget {
  const _MechanicProfileSheet({
    required this.offer,
    required this.type,
    required this.onSelect,
  });
  final MechanicOffer offer;
  final MechanicType type;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final isGarage = type == MechanicType.garage;
    // Show at 92% screen height so it feels immersive but the background is still visible
    final height = MediaQuery.of(context).size.height * 0.92;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          const _DragHandle(),
          // Scrollable content
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _CustomerTrustHeader(offer: offer, type: type),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _CustomerSpecialization(skills: offer.skills, type: type),
                      const SizedBox(height: 14),
                      if (isGarage)
                        _CustomerGarageLayer()
                      else
                        _CustomerMobileLayer(),
                      const SizedBox(height: 14),
                      _CustomerServicesSection(type: type),
                      const SizedBox(height: 14),
                      _CustomerReviewsSection(),
                      const SizedBox(height: 14),
                      _DistanceEtaRow(offer: offer),
                      // Space for the sticky bottom bar
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          // Sticky action bar — stays pinned at the bottom
          _ActionBar(offer: offer, type: type, onSelect: onSelect),
        ],
      ),
    );
  }
}

// ── Drag handle ────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(color: context.divider, borderRadius: BorderRadius.circular(2)),
      ),
    );
  }
}

// ── Trust Header ───────────────────────────────────────────────────────────────
// The first thing the customer sees — answers "Is this person real?"

class _CustomerTrustHeader extends StatelessWidget {
  const _CustomerTrustHeader({required this.offer, required this.type});
  final MechanicOffer offer;
  final MechanicType type;

  @override
  Widget build(BuildContext context) {
    final isGarage = type == MechanicType.garage;

    return Container(
      color: context.surface,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Garage = rounded square; Mobile = circle
              isGarage
                  ? Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.store_rounded, size: 36, color: AppColors.primary),
                    )
                  : CircleAvatar(
                      radius: 36,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        offer.name.isNotEmpty ? offer.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer.name,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: context.textDark),
                    ),
                    const SizedBox(height: 5),
                    _TrustBadge(type: type),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 13, color: context.textGrey),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            isGarage ? 'Westlands, Nairobi' : 'Serves: Westlands, Kilimani, Parklands',
                            style: TextStyle(fontSize: 12, color: context.textGrey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Rating row
          Row(
            children: [
              ...List.generate(5, (i) {
                if (i < offer.rating.floor()) return const Icon(Icons.star_rounded, size: 16, color: AppColors.warning);
                if (i < offer.rating) return const Icon(Icons.star_half_rounded, size: 16, color: AppColors.warning);
                return const Icon(Icons.star_outline_rounded, size: 16, color: AppColors.warning);
              }),
              const SizedBox(width: 6),
              Text(
                offer.rating.toStringAsFixed(1),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textDark),
              ),
              const SizedBox(width: 4),
              Text('(${offer.reviewCount} reviews)', style: TextStyle(fontSize: 12, color: context.textGrey)),
              const SizedBox(width: 8),
              Container(width: 1, height: 12, color: context.divider),
              const SizedBox(width: 8),
              Icon(Icons.check_circle_rounded, size: 13, color: AppColors.success),
              const SizedBox(width: 3),
              Text('${offer.reviewCount * 2 + 30} jobs', style: TextStyle(fontSize: 12, color: context.textGrey)),
            ],
          ),
          const SizedBox(height: 10),
          // Operating status — read-only for customer
          _StatusPill(isGarage: isGarage),
        ],
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.type});
  final MechanicType type;

  @override
  Widget build(BuildContext context) {
    final isGarage = type == MechanicType.garage;
    const green = Color(0xFF1A6B3C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isGarage ? green.withValues(alpha: 0.1) : AppColors.primarySurface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isGarage ? green.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGarage ? Icons.verified_rounded : Icons.verified_user_rounded,
            size: 12,
            color: isGarage ? green : AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            isGarage ? 'Fundix Approved Garage' : 'Verified Mobile Technician',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isGarage ? green : AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isGarage});
  final bool isGarage;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            isGarage ? 'Open now' : 'Online · Available',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

// ── Specialization ─────────────────────────────────────────────────────────────
// Answers "Can they handle my issue?"

class _CustomerSpecialization extends StatelessWidget {
  const _CustomerSpecialization({required this.skills, required this.type});
  final List<String> skills;
  final MechanicType type;

  @override
  Widget build(BuildContext context) {
    final bestFor = type == MechanicType.garage
        ? ['Best for accident repair', 'Best for diagnostics', 'Best for Japanese cars']
        : ['Best for emergency battery', 'Best for quick inspections'];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(icon: Icons.workspace_premium_rounded, label: 'Specialization'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: skills.map((s) => _Chip(label: s, isPrimary: true)).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.thumb_up_alt_outlined, size: 13, color: context.textGrey),
              const SizedBox(width: 5),
              Text('Best For', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textDark)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bestFor.map((tag) => _BestForPill(label: tag)).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Garage Layer ───────────────────────────────────────────────────────────────
// Answers "Does this place exist?"

class _CustomerGarageLayer extends StatelessWidget {
  const _CustomerGarageLayer();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(icon: Icons.store_outlined, label: 'Garage'),
          const SizedBox(height: 12),
          // Photo placeholders (customer can see the garage looks real)
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _PhotoPlaceholder(label: 'Front'),
                const SizedBox(width: 8),
                _PhotoPlaceholder(label: 'Work Bay'),
                const SizedBox(width: 8),
                _PhotoPlaceholder(label: 'Equipment'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Stats
          Row(
            children: [
              _StatItem(icon: Icons.history_rounded, value: '12 years', label: 'Experience'),
              _Divider(),
              _StatItem(icon: Icons.people_rounded, value: '5 techs', label: 'Team'),
              _Divider(),
              _StatItem(icon: Icons.location_on_rounded, value: 'Westlands', label: 'Location'),
            ],
          ),
          const SizedBox(height: 14),
          Text('Equipment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textDark)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: ['Diagnostic Scanner', 'Hydraulic Lift', 'Spray Booth', 'Wheel Alignment']
                .map((e) => _EquipTag(label: e))
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ── Mobile Layer ───────────────────────────────────────────────────────────────

class _CustomerMobileLayer extends StatelessWidget {
  const _CustomerMobileLayer();

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1A6B3C);
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(icon: Icons.directions_car_rounded, label: 'Mobile Coverage'),
          const SizedBox(height: 12),
          Text('Operational Zones', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textDark)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: ['Westlands', 'Kilimani', 'Parklands', 'Ngong Road'].map((z) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, size: 11, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Text(z, style: TextStyle(fontSize: 11, color: context.textDark)),
                ],
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoTile(icon: Icons.access_time_rounded, label: 'Available', value: '8AM – 6PM'),
              const SizedBox(width: 10),
              _InfoTile(icon: Icons.two_wheeler_rounded, label: 'Transport', value: 'Motorcycle'),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: green.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: green.withValues(alpha: 0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, size: 14, color: green),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Only accepts jobs in verified safe zones.',
                      style: TextStyle(fontSize: 11, color: green, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Services ───────────────────────────────────────────────────────────────────
// Answers "Will I get scammed?"

class _CustomerServicesSection extends StatelessWidget {
  const _CustomerServicesSection({required this.type});
  final MechanicType type;

  static const _garage = [
    ('Diagnostics', 'KES 1,500 – 3,000'),
    ('Brake Service', 'KES 2,500 – 6,000'),
    ('Suspension Check', 'KES 3,000 – 8,000'),
    ('Accident Repair', 'Inspection required'),
    ('Oil Change', 'KES 1,200 – 2,500'),
  ];

  static const _mobile = [
    ('Battery Jumpstart', 'KES 500 – 1,000'),
    ('Tire Replacement', 'KES 800 – 1,500'),
    ('Basic Diagnostics', 'KES 1,000 – 2,000'),
    ('Overheating Inspection', 'KES 800 – 1,500'),
    ('Minor Electrical', 'KES 600 – 1,200'),
  ];

  @override
  Widget build(BuildContext context) {
    final services = type == MechanicType.garage ? _garage : _mobile;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(icon: Icons.handyman_rounded, label: 'Services & Pricing'),
          const SizedBox(height: 4),
          Text('Estimated ranges — final quote after inspection',
              style: TextStyle(fontSize: 11, color: context.textGrey)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(border: Border.all(color: context.divider), borderRadius: BorderRadius.circular(10)),
            child: Column(
              children: [
                for (int i = 0; i < services.length; i++)
                  _ServiceRow(name: services[i].$1, range: services[i].$2, showDivider: i < services.length - 1),
              ],
            ),
          ),
          if (type == MechanicType.mobile) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 13, color: AppColors.warning),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text('Limited to roadside-safe jobs only.',
                        style: TextStyle(fontSize: 11, color: AppColors.warning)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({required this.name, required this.range, this.showDivider = true});
  final String name;
  final String range;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Expanded(child: Text(name, style: TextStyle(fontSize: 13, color: context.textDark, fontWeight: FontWeight.w500))),
              Text(range, style: TextStyle(fontSize: 12, color: context.textGrey)),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, color: context.divider),
      ],
    );
  }
}

// ── Reviews ────────────────────────────────────────────────────────────────────
// Answers "Will they disappear?"

class _CustomerReviewsSection extends StatelessWidget {
  const _CustomerReviewsSection();

  static final _reviews = [
    (
      name: 'John M.',
      rating: 5,
      date: '2 weeks ago',
      text: 'Transparent pricing and updated me daily. Car came back looking brand new.',
    ),
    (
      name: 'Sarah K.',
      rating: 5,
      date: '1 month ago',
      text: 'Diagnosed the issue quickly. Done within the same day. Very professional.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(icon: Icons.star_rounded, label: 'Customer Reviews'),
          const SizedBox(height: 12),
          for (final r in _reviews)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primarySurface,
                          child: Text(r.name[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: context.textDark)),
                              Row(
                                children: [
                                  ...List.generate(r.rating, (_) => const Icon(Icons.star_rounded, size: 10, color: AppColors.warning)),
                                  const SizedBox(width: 4),
                                  Text(r.date, style: TextStyle(fontSize: 10, color: context.textGrey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('"${r.text}"', style: TextStyle(fontSize: 12, color: context.textGrey, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Distance / ETA row ─────────────────────────────────────────────────────────
// Answers "Where are they?"

class _DistanceEtaRow extends StatelessWidget {
  const _DistanceEtaRow({required this.offer});
  final MechanicOffer offer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.divider),
      ),
      child: Row(
        children: [
          _EtaStat(icon: Icons.near_me_rounded, value: '${offer.distanceKm.toStringAsFixed(1)} km', label: 'Distance'),
          Container(width: 1, height: 32, color: context.divider, margin: const EdgeInsets.symmetric(horizontal: 16)),
          _EtaStat(icon: Icons.schedule_rounded, value: '~${offer.etaMinutes} min', label: 'ETA'),
          Container(width: 1, height: 32, color: context.divider, margin: const EdgeInsets.symmetric(horizontal: 16)),
          _EtaStat(icon: Icons.payments_outlined, value: 'KES ${offer.priceEstimate.toStringAsFixed(0)}', label: 'Est. cost'),
        ],
      ),
    );
  }
}

class _EtaStat extends StatelessWidget {
  const _EtaStat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: context.textDark)),
          Text(label, style: TextStyle(fontSize: 10, color: context.textGrey)),
        ],
      ),
    );
  }
}

// ── Action bar ─────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.offer, required this.type, required this.onSelect});
  final MechanicOffer offer;
  final MechanicType type;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final label = type == MechanicType.garage ? 'Select ${offer.name}' : 'Request ${offer.name}';

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(top: BorderSide(color: context.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onSelect();
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: Text(label),
            ),
          ),
          const SizedBox(width: 12),
          // Call button — placeholder until phone integration
          Container(
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: IconButton(
              icon: const Icon(Icons.call_rounded, color: AppColors.success),
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling — coming soon')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared micro-widgets ───────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.divider),
      ),
      child: child,
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 7),
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textDark)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.isPrimary = false});
  final String label;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
    );
  }
}

class _BestForPill extends StatelessWidget {
  const _BestForPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1A6B3C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: green.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 11, color: green),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: green)),
        ],
      ),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(color: context.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: context.divider)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_outlined, size: 20, color: context.textGrey),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 9, color: context.textGrey)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textDark)),
          Text(label, style: TextStyle(fontSize: 10, color: context.textGrey)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => Container(width: 1, height: 36, color: context.divider);
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: context.bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: context.divider)),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 9, color: context.textGrey)),
                Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textDark)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EquipTag extends StatelessWidget {
  const _EquipTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: context.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: context.divider)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 11, color: AppColors.success),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: context.textDark)),
        ],
      ),
    );
  }
}
