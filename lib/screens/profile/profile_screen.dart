import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme_ext.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../models/app_user.dart';
import '../../models/vehicle.dart';
import '../../services/customer_api_service.dart';
import '../dev/role_switcher.dart';
import 'customer_settings_screen.dart';

final _customerProfileProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  return CustomerApiService.getProfile();
});

final _customerVehiclesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return CustomerApiService.getVehicles();
});

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(localeProvider);
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: Text(t('profile', lang)),
        backgroundColor: context.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: context.textGrey),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CustomerSettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const _ProfileHero(),
          const SizedBox(height: 28),
          _AccountMenu(lang: lang),
          const SizedBox(height: 12),
          _SignOutButton(lang: lang),
          if (RoleSwitcherScreen.isAvailable) ...[
            const SizedBox(height: 12),
            _DevRoleSwitcherButton(),
          ],
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.lang, required this.user});
  final String lang;
  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final displayName = user?.name ?? 'You';
    final displayEmail = user?.email ?? '';
    final roleLabel = user?.role == UserRole.mechanic ? 'Mechanic' : 'Customer';

    return Column(
      children: [
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 46,
              backgroundColor: context.primarySurface,
              child: const Icon(Icons.person_rounded, size: 48, color: AppColors.primary),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: context.surface,
                shape: BoxShape.circle,
                border: Border.all(color: context.divider, width: 1.5),
              ),
              child: Icon(Icons.edit_outlined, size: 14, color: context.textGrey),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          displayName,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.textDark),
        ),
        const SizedBox(height: 4),
        Text(
          displayEmail,
          style: TextStyle(fontSize: 13, color: context.textGrey),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: context.primarySurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            roleLabel,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _AccountMenu extends ConsumerWidget {
  const _AccountMenu({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.directions_car_rounded, color: context.textGrey, size: 22),
            title: Text(
              t('my_vehicles', lang),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textDark),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: context.inactive, size: 20),
            onTap: () => _showVehiclesSheet(context, ref),
          ),
          Divider(height: 1, indent: 56, color: context.divider),
          ListTile(
            leading: Icon(Icons.payment_outlined, color: context.textGrey, size: 22),
            title: Text(
              t('payment_methods', lang),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textDark),
            ),
            trailing: Icon(Icons.chevron_right_rounded, color: context.inactive, size: 20),
            onTap: () => _showPaymentSheet(context),
          ),
        ],
      ),
    );
  }

  void _showVehiclesSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _VehiclesSheet(),
    );
  }

  void _showPaymentSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _PaymentMethodsSheet(),
    );
  }
}

// ── Vehicles bottom sheet ──────────────────────────────────────────────────────

class _VehiclesSheet extends ConsumerStatefulWidget {
  const _VehiclesSheet();

  @override
  ConsumerState<_VehiclesSheet> createState() => _VehiclesSheetState();
}

class _VehiclesSheetState extends ConsumerState<_VehiclesSheet> {
  bool _showForm = false;
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  String _fuelType = 'Petrol';
  String _transmission = 'Auto';

  bool get _formValid =>
      _makeCtrl.text.trim().isNotEmpty &&
      _modelCtrl.text.trim().isNotEmpty &&
      _yearCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  void _saveVehicle() {
    if (!_formValid) return;
    final year = int.tryParse(_yearCtrl.text.trim()) ?? DateTime.now().year;
    final v = Vehicle(
      id: 'v_${DateTime.now().millisecondsSinceEpoch}',
      brand: _makeCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      year: year,
      fuelType: _fuelType,
      transmission: _transmission,
      bodyType: 'Sedan',
    );
    ref.read(vehicleProvider.notifier).addVehicle(v);
    setState(() {
      _showForm = false;
      _makeCtrl.clear();
      _modelCtrl.clear();
      _yearCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = ref.watch(vehicleProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  const Text('My Vehicles',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                  const Spacer(),
                  if (!_showForm)
                    TextButton.icon(
                      onPressed: () => setState(() => _showForm = true),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: const Text('Add'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                ],
              ),
            ),
            const Divider(color: AppColors.divider, height: 16),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  if (_showForm) ...[
                    _VehicleAddForm(
                      makeCtrl: _makeCtrl,
                      modelCtrl: _modelCtrl,
                      yearCtrl: _yearCtrl,
                      fuelType: _fuelType,
                      transmission: _transmission,
                      formValid: _formValid,
                      onFuelTypeChanged: (v) => setState(() => _fuelType = v),
                      onTransmissionChanged: (v) => setState(() => _transmission = v),
                      onSave: _saveVehicle,
                      onCancel: () => setState(() => _showForm = false),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),
                  ],
                  if (vehicles.isEmpty && !_showForm)
                    _EmptyVehiclesState(onAdd: () => setState(() => _showForm = true))
                  else ...[
                    ...vehicles.map((v) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _VehicleTile(
                            vehicle: v,
                            onRemove: () => ref.read(vehicleProvider.notifier).removeVehicle(v.id),
                          ),
                        )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleAddForm extends StatefulWidget {
  const _VehicleAddForm({
    required this.makeCtrl,
    required this.modelCtrl,
    required this.yearCtrl,
    required this.fuelType,
    required this.transmission,
    required this.formValid,
    required this.onFuelTypeChanged,
    required this.onTransmissionChanged,
    required this.onSave,
    required this.onCancel,
  });
  final TextEditingController makeCtrl;
  final TextEditingController modelCtrl;
  final TextEditingController yearCtrl;
  final String fuelType;
  final String transmission;
  final bool formValid;
  final ValueChanged<String> onFuelTypeChanged;
  final ValueChanged<String> onTransmissionChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  State<_VehicleAddForm> createState() => _VehicleAddFormState();
}

class _VehicleAddFormState extends State<_VehicleAddForm> {
  @override
  void initState() {
    super.initState();
    widget.makeCtrl.addListener(() => setState(() {}));
    widget.modelCtrl.addListener(() => setState(() {}));
    widget.yearCtrl.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add New Vehicle',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 14),
          _SheetField(label: 'Make', hint: 'e.g. Toyota, Nissan', controller: widget.makeCtrl),
          const SizedBox(height: 12),
          _SheetField(label: 'Model', hint: 'e.g. Corolla, X-Trail', controller: widget.modelCtrl),
          const SizedBox(height: 12),
          _SheetField(
            label: 'Year',
            hint: 'e.g. 2018',
            controller: widget.yearCtrl,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          _LabelRow(label: 'Fuel Type'),
          const SizedBox(height: 6),
          _ChipSelector(
            options: Vehicle.fuelTypes,
            selected: widget.fuelType,
            onSelect: widget.onFuelTypeChanged,
          ),
          const SizedBox(height: 12),
          _LabelRow(label: 'Transmission'),
          const SizedBox(height: 6),
          _ChipSelector(
            options: Vehicle.transmissionTypes,
            selected: widget.transmission,
            onSelect: widget.onTransmissionChanged,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: widget.formValid ? widget.onSave : null,
                  child: const Text('Save Vehicle'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({required this.vehicle, required this.onRemove});
  final Vehicle vehicle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: const BoxDecoration(
              color: AppColors.primarySurface, shape: BoxShape.circle),
            child: const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vehicle.displayName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(vehicle.subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
            onPressed: () => _confirmRemove(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Vehicle'),
        content: Text('Remove ${vehicle.displayName} from your account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              onRemove();
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _EmptyVehiclesState extends StatelessWidget {
  const _EmptyVehiclesState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
            child: const Icon(Icons.directions_car_rounded, color: AppColors.primary, size: 32),
          ),
          const SizedBox(height: 14),
          const Text('No vehicles added yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
          const SizedBox(height: 4),
          const Text('Add a vehicle to make requesting service faster',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add Vehicle'),
          ),
        ],
      ),
    );
  }
}

// ── Payment methods bottom sheet ───────────────────────────────────────────────

class _PaymentMethodsSheet extends StatefulWidget {
  const _PaymentMethodsSheet();

  @override
  State<_PaymentMethodsSheet> createState() => _PaymentMethodsSheetState();
}

class _PaymentMethodsSheetState extends State<_PaymentMethodsSheet> {
  bool _showMpesaForm = false;
  final _mpesaCtrl = TextEditingController();

  @override
  void dispose() {
    _mpesaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 24 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Payment Methods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark)),
          const SizedBox(height: 4),
          const Text('Payments are processed securely via M-Pesa',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
          const SizedBox(height: 20),

          // M-Pesa saved
          _PaymentTile(
            icon: Icons.phone_android_rounded,
            label: 'M-Pesa',
            sublabel: '+254 7XX XXX XXX · Default',
            color: AppColors.success,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Active',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
            ),
            onTap: () => setState(() => _showMpesaForm = !_showMpesaForm),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: _showMpesaForm
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Update M-Pesa Number',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                          const SizedBox(height: 10),
                          _SheetField(
                            label: 'Phone Number',
                            hint: '+254 7XX XXX XXX',
                            controller: _mpesaCtrl,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() => _showMpesaForm = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('M-Pesa number updated')),
                                );
                              },
                              child: const Text('Save Number'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 10),

          // Add card (coming soon)
          _PaymentTile(
            icon: Icons.credit_card_rounded,
            label: 'Add Bank Card',
            sublabel: 'Visa, Mastercard — coming soon',
            color: AppColors.primary,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Soon',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Card payments — coming soon')),
            ),
          ),
          const SizedBox(height: 10),

          // Bank transfer (coming soon)
          _PaymentTile(
            icon: Icons.account_balance_outlined,
            label: 'Bank Transfer',
            sublabel: 'Direct bank payment — coming soon',
            color: const Color(0xFF6366F1),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Soon',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6366F1))),
            ),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bank transfer — coming soon')),
            ),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline_rounded, color: AppColors.success, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'All transactions are encrypted and processed securely.',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
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

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.trailing,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final Widget trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  const SizedBox(height: 2),
                  Text(sublabel,
                      style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

// ── Shared form helpers ────────────────────────────────────────────────────────

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
  });
  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textGrey),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        ),
      ],
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark));
  }
}

class _ChipSelector extends StatelessWidget {
  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.onSelect,
  });
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: options.map((opt) {
        final isSelected = selected == opt;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primarySurface : AppColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.divider,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Text(
              opt,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textGrey,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Sign out & dev buttons ────────────────────────────────────────────────────

class _SignOutButton extends ConsumerWidget {
  const _SignOutButton({required this.lang});
  final String lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.divider),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
        title: Text(
          t('sign_out', lang),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.error),
        ),
        onTap: () => _showSignOutDialog(context, ref, lang),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref, String lang) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(t('sign_out', lang)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).signOut();
            },
            child: Text(t('sign_out', lang)),
          ),
        ],
      ),
    );
  }
}

class _DevRoleSwitcherButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoleSwitcherScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2D2D4E)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swap_horiz_rounded, color: Color(0xFF7C7CFF), size: 18),
            SizedBox(width: 8),
            Text(
              'DEV — Switch Role',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: Color(0xFF7C7CFF), letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
