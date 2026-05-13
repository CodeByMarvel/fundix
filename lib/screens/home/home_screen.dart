import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../providers/job_notifier.dart';
import '../../models/job_status.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobState = ref.watch(jobProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good morning 👋',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textGrey)),
            Text('Find a Mechanic',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primarySurface,
              child: const Icon(Icons.notifications_outlined,
                  color: AppColors.primary, size: 20),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          if (jobState.hasActiveJob)
            _ActiveRequestBanner(status: jobState.customerStatus),
          if (jobState.hasActiveJob) const SizedBox(height: 16),
          const _SearchBar(),
          const SizedBox(height: 24),
          const _SectionLabel('What do you need help with?'),
          const SizedBox(height: 12),
          _CategoryGrid(
            onCategoryTap: (category) =>
                _showRequestSheet(context, ref, preselectedCategory: category),
          ),
          const SizedBox(height: 24),
          const _SectionLabel('Nearby Mechanics'),
          const SizedBox(height: 12),
          const _NearbyPlaceholder(),
        ],
      ),
    );
  }
}

void _showRequestSheet(BuildContext context, WidgetRef ref,
    {String? preselectedCategory}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _HomeRequestSheet(
      preselectedCategory: preselectedCategory,
      onSubmit: (desc, car, cat, loc) =>
          ref.read(jobProvider.notifier).submitRequest(
                description: desc,
                carType: car,
                location: loc,
                manualCategory: cat,
              ),
    ),
  );
}

// Banner shown when a request is already active
class _ActiveRequestBanner extends StatelessWidget {
  const _ActiveRequestBanner({required this.status});
  final CustomerRequestStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: AppColors.primary, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(status.displayLabel,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.primary, size: 18),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Row(
        children: [
          Icon(Icons.search_rounded, color: AppColors.textLight, size: 20),
          SizedBox(width: 10),
          Text('Search by problem or car type…',
              style: TextStyle(color: AppColors.textLight, fontSize: 14)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
            letterSpacing: -0.2));
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.onCategoryTap});
  final ValueChanged<String> onCategoryTap;

  static const _categories = [
    (Icons.battery_charging_full_rounded, 'Battery', AppColors.warning),
    (Icons.tire_repair_rounded, 'Tire', AppColors.primary),
    (Icons.settings_outlined, 'Engine', AppColors.error),
    (Icons.oil_barrel_outlined, 'Oil Change', AppColors.success),
    (Icons.electric_bolt_rounded, 'Electrical', Color(0xFF6366F1)),
    (Icons.more_horiz_rounded, 'More', AppColors.textGrey),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: _categories
          .map((c) => _CategoryChip(
                icon: c.$1,
                label: c.$2,
                color: c.$3,
                onTap: () => onCategoryTap(c.$2),
              ))
          .toList(),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark)),
          ],
        ),
      ),
    );
  }
}

class _NearbyPlaceholder extends StatelessWidget {
  const _NearbyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined,
                size: 40,
                color: AppColors.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            const Text('Map view coming soon',
                style: TextStyle(color: AppColors.textGrey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thin request sheet used from Home (mirrors the one in requests_screen)
// ─────────────────────────────────────────────────────────────────────────────

class _HomeRequestSheet extends StatefulWidget {
  const _HomeRequestSheet(
      {this.preselectedCategory, required this.onSubmit});
  final String? preselectedCategory;
  final void Function(String desc, String car, String? cat, String loc) onSubmit;

  @override
  State<_HomeRequestSheet> createState() => _HomeRequestSheetState();
}

class _HomeRequestSheetState extends State<_HomeRequestSheet> {
  final _descController = TextEditingController();
  final _carController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.preselectedCategory != null) {
      _descController.text = '${widget.preselectedCategory} issue';
    }
  }

  @override
  void dispose() {
    _descController.dispose();
    _carController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_descController.text.trim().isEmpty) return;
    Navigator.of(context).pop();
    widget.onSubmit(
      _descController.text.trim(),
      _carController.text.trim(),
      widget.preselectedCategory,
      'Nairobi, Kenya',
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPad),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Request a Mechanic',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
              if (widget.preselectedCategory != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(widget.preselectedCategory!,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(hintText: 'Describe the problem…'),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _carController,
            decoration:
                const InputDecoration(hintText: 'Car type (e.g. Toyota Corolla)'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _descController.text.trim().isNotEmpty ? _submit : null,
              child: const Text('Find Mechanic'),
            ),
          ),
        ],
      ),
    );
  }
}
