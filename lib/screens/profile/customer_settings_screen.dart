import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme_ext.dart';
import '../../providers/theme_provider.dart';
import '../../providers/locale_provider.dart';

class CustomerSettingsScreen extends ConsumerStatefulWidget {
  const CustomerSettingsScreen({super.key});

  @override
  ConsumerState<CustomerSettingsScreen> createState() => _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState extends ConsumerState<CustomerSettingsScreen> {
  // App Preferences
  String _theme = 'System';
  String _dataUsage = 'Standard';

  // Notifications
  bool _jobRequestUpdates = true;
  bool _mechanicArrivalUpdates = true;
  bool _paymentNotifications = true;
  bool _systemAnnouncements = true;
  bool _promotionalNotifications = false;

  // Account
  bool _phoneVerified = true;
  bool _emailVerified = false;

  // Saved addresses mock
  final List<Map<String, String>> _savedAddresses = [
    {'label': 'Home', 'address': '14 Kiambu Road, Nairobi'},
    {'label': 'Work', 'address': 'The Hub Karen, Lang\'ata Road'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: context.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 48),
        children: [
          _sectionLabel('App Preferences'),
          _SettingsCard(children: [
            _ToggleTile(
              icon: Icons.dark_mode_outlined,
              label: 'Dark Mode',
              value: ref.watch(themeModeProvider) == ThemeMode.dark,
              onChanged: (v) {
                ref.read(themeModeProvider.notifier).state =
                    v ? ThemeMode.dark : ThemeMode.light;
              },
            ),
            _divider(),
            _NavTile(
              icon: Icons.palette_outlined,
              label: 'Theme',
              value: _theme,
              onTap: () => _showOptionSheet(
                context,
                title: 'Theme',
                options: const ['Light', 'Dark', 'System'],
                selected: _theme,
                onSelected: (v) => setState(() {
                  _theme = v;
                  if (v == 'Dark') {
                    ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
                  } else if (v == 'Light') {
                    ref.read(themeModeProvider.notifier).state = ThemeMode.light;
                  } else {
                    ref.read(themeModeProvider.notifier).state = ThemeMode.system;
                  }
                }),
              ),
            ),
            _divider(),
            _NavTile(
              icon: Icons.language_outlined,
              label: 'Language',
              value: ref.watch(localeProvider) == 'sw' ? 'Swahili' : 'English',
              onTap: () {
                final currentLang = ref.read(localeProvider);
                _showOptionSheet(
                  context,
                  title: 'Language',
                  options: const ['English', 'Swahili'],
                  selected: currentLang == 'sw' ? 'Swahili' : 'English',
                  onSelected: (v) {
                    ref.read(localeProvider.notifier).state =
                        v == 'Swahili' ? 'sw' : 'en';
                  },
                );
              },
            ),
            _divider(),
            _NavTile(
              icon: Icons.data_usage_outlined,
              label: 'Data Usage',
              value: _dataUsage,
              onTap: () => _showOptionSheet(
                context,
                title: 'Data Usage',
                options: const ['Low', 'Standard', 'High'],
                selected: _dataUsage,
                onSelected: (v) => setState(() => _dataUsage = v),
              ),
            ),
            _divider(),
            _ActionTile(
              icon: Icons.cleaning_services_outlined,
              label: 'Clear Cache',
              onTap: () => _showClearCacheDialog(context),
            ),
          ]),
          const SizedBox(height: 20),
          _sectionLabel('Notifications'),
          _SettingsCard(children: [
            _ToggleTile(
              icon: Icons.work_outline_rounded,
              label: 'Job Request Updates',
              value: _jobRequestUpdates,
              onChanged: (v) => setState(() => _jobRequestUpdates = v),
            ),
            _divider(),
            _ToggleTile(
              icon: Icons.directions_car_outlined,
              label: 'Mechanic Arrival Updates',
              value: _mechanicArrivalUpdates,
              onChanged: (v) => setState(() => _mechanicArrivalUpdates = v),
            ),
            _divider(),
            _ToggleTile(
              icon: Icons.receipt_outlined,
              label: 'Payment & Transactions',
              value: _paymentNotifications,
              onChanged: (v) => setState(() => _paymentNotifications = v),
            ),
            _divider(),
            _ToggleTile(
              icon: Icons.campaign_outlined,
              label: 'System Announcements',
              value: _systemAnnouncements,
              onChanged: (v) => setState(() => _systemAnnouncements = v),
            ),
            _divider(),
            _ToggleTile(
              icon: Icons.local_offer_outlined,
              label: 'Promotional Notifications',
              subtitle: 'Occasional weekly or biweekly updates',
              value: _promotionalNotifications,
              onChanged: (v) => setState(() => _promotionalNotifications = v),
            ),
          ]),
          const SizedBox(height: 20),
          _sectionLabel('Location & Service'),
          _SettingsCard(children: [
            _NavTile(
              icon: Icons.bookmark_outline_rounded,
              label: 'Saved Addresses',
              onTap: () => _showSavedAddressesSheet(context),
            ),
            _divider(),
            _NavTile(
              icon: Icons.my_location_outlined,
              label: 'Default Service Location',
              onTap: () => _showDefaultLocationSheet(context),
            ),
            _divider(),
            _NavTile(
              icon: Icons.gps_fixed_outlined,
              label: 'Location Permissions',
              onTap: () => _showLocationPermissionsDialog(context),
            ),
          ]),
          const SizedBox(height: 20),
          _sectionLabel('Account & Security'),
          _SettingsCard(children: [
            _NavTile(
              icon: Icons.lock_outline_rounded,
              label: 'Change Password',
              onTap: () => _showChangePasswordSheet(context),
            ),
            _divider(),
            _NavTile(
              icon: Icons.phone_outlined,
              label: 'Phone Verification',
              badge: _phoneVerified ? _VerifiedBadge() : _UnverifiedBadge(),
              onTap: () => _showPhoneVerificationSheet(context),
            ),
            _divider(),
            _NavTile(
              icon: Icons.email_outlined,
              label: 'Email Verification',
              badge: _emailVerified ? _VerifiedBadge() : _UnverifiedBadge(),
              onTap: () => _showEmailVerificationSheet(context),
            ),
            _divider(),
            _NavTile(
              icon: Icons.devices_outlined,
              label: 'Login Sessions',
              onTap: () => _showLoginSessionsSheet(context),
            ),
            _divider(),
            _NavTile(
              icon: Icons.security_outlined,
              label: 'Two-Factor Authentication',
              badge: _ComingSoonBadge(),
              onTap: () => _showComingSoonDialog(context, 'Two-Factor Authentication'),
            ),
          ]),
          const SizedBox(height: 20),
          _sectionLabel('Support & Help'),
          _SettingsCard(children: [
            _NavTile(
              icon: Icons.help_center_outlined,
              label: 'Help Center',
              onTap: () => _showHelpCenterSheet(context),
            ),
            _divider(),
            _NavTile(
              icon: Icons.quiz_outlined,
              label: 'FAQs',
              onTap: () => _showFAQsSheet(context),
            ),
            _divider(),
            _NavTile(
              icon: Icons.headset_mic_outlined,
              label: 'Contact Support',
              onTap: () => _showContactSupportSheet(context),
            ),
            _divider(),
            _NavTile(
              icon: Icons.flag_outlined,
              label: 'Report a Problem',
              onTap: () => _showReportProblemSheet(context),
            ),
            _divider(),
            _NavTile(
              icon: Icons.article_outlined,
              label: 'Terms & Conditions',
              onTap: () => _showLegalSheet(context, title: 'Terms & Conditions', content: _termsContent),
            ),
            _divider(),
            _NavTile(
              icon: Icons.privacy_tip_outlined,
              label: 'Privacy Policy',
              onTap: () => _showLegalSheet(context, title: 'Privacy Policy', content: _privacyContent),
            ),
          ]),
        ],
      ),
    );
  }

  // ─── Section helpers ────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: context.textGrey,
          ),
        ),
      );

  Widget _divider() => Divider(height: 1, indent: 52, color: context.divider);

  // ─── App Preferences actions ─────────────────────────────────────────────

  void _showOptionSheet(
    BuildContext context, {
    required String title,
    required List<String> options,
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OptionSheetBody(
        title: title,
        options: options,
        selected: selected,
        onSelected: (v) {
          onSelected(v);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Cache', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
          'This will clear all locally stored images and temporary data. Your account and request history will not be affected.',
          style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  // ─── Location actions ─────────────────────────────────────────────────────

  void _showSavedAddressesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (_, scrollController) => Column(
            children: [
              _sheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Saved Addresses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      onPressed: () => _showAddAddressDialog(context, setSheetState),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _savedAddresses.isEmpty
                    ? const Center(child: Text('No saved addresses', style: TextStyle(color: AppColors.textGrey)))
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _savedAddresses.length,
                        separatorBuilder: (context, i) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final addr = _savedAddresses[i];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
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
                                  child: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(addr['label']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                                      const SizedBox(height: 2),
                                      Text(addr['address']!, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                                  onPressed: () => setSheetState(() => _savedAddresses.removeAt(i)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddAddressDialog(BuildContext context, StateSetter setSheetState) {
    final labelCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelCtrl, decoration: const InputDecoration(hintText: 'Label (e.g. Home, Work)')),
            const SizedBox(height: 12),
            TextField(controller: addrCtrl, decoration: const InputDecoration(hintText: 'Full address')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            onPressed: () {
              if (labelCtrl.text.isNotEmpty && addrCtrl.text.isNotEmpty) {
                setSheetState(() {
                  _savedAddresses.add({'label': labelCtrl.text, 'address': addrCtrl.text});
                });
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDefaultLocationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _OptionSheetBody(
        title: 'Default Service Location',
        options: [
          ..._savedAddresses.map((a) => '${a['label']} — ${a['address']}'),
          'Use Current Location',
        ],
        selected: 'Use Current Location',
        onSelected: (_) => Navigator.of(context).pop(),
      ),
    );
  }

  void _showLocationPermissionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Location Permissions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text(
          'Fundi-X uses your location to match you with nearby mechanics and provide accurate arrival times.\n\nTo manage location permissions, go to your device Settings → Apps → Fundi-X → Permissions.',
          style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.6),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  // ─── Account & Security actions ───────────────────────────────────────────

  void _showChangePasswordSheet(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                const SizedBox(height: 8),
                const Text('Change Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 20),
                _passwordField(ctrl: currentCtrl, hint: 'Current password', obscure: obscureCurrent, toggle: () => setSheetState(() => obscureCurrent = !obscureCurrent)),
                const SizedBox(height: 12),
                _passwordField(ctrl: newCtrl, hint: 'New password', obscure: obscureNew, toggle: () => setSheetState(() => obscureNew = !obscureNew)),
                const SizedBox(height: 12),
                _passwordField(ctrl: confirmCtrl, hint: 'Confirm new password', obscure: obscureNew, toggle: null),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Password updated successfully'), behavior: SnackBarBehavior.floating),
                      );
                    },
                    child: const Text('Update Password'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _passwordField({required TextEditingController ctrl, required String hint, required bool obscure, VoidCallback? toggle}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: toggle != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.textGrey),
                onPressed: toggle,
              )
            : null,
      ),
    );
  }

  void _showPhoneVerificationSheet(BuildContext context) {
    final phoneCtrl = TextEditingController(text: '+254 712 345 678');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Phone Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(width: 8),
                  if (_phoneVerified) _VerifiedBadge(),
                ],
              ),
              const SizedBox(height: 16),
              if (_phoneVerified)
                _infoBox(Icons.check_circle_outline, 'Your phone number is verified.', AppColors.success)
              else
                _infoBox(Icons.warning_amber_outlined, 'Your phone number is not verified yet.', AppColors.warning),
              const SizedBox(height: 16),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(hintText: 'Phone number', prefixIcon: Icon(Icons.phone_outlined))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _phoneVerified = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification code sent'), behavior: SnackBarBehavior.floating),
                    );
                  },
                  child: Text(_phoneVerified ? 'Update Phone Number' : 'Send Verification Code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmailVerificationSheet(BuildContext context) {
    final emailCtrl = TextEditingController(text: 'customer@email.com');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Email Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(width: 8),
                  if (_emailVerified) _VerifiedBadge() else _UnverifiedBadge(),
                ],
              ),
              const SizedBox(height: 16),
              if (_emailVerified)
                _infoBox(Icons.check_circle_outline, 'Your email address is verified.', AppColors.success)
              else
                _infoBox(Icons.info_outline, 'Verify your email to secure your account and receive important updates.', AppColors.primary),
              const SizedBox(height: 16),
              TextField(controller: emailCtrl, decoration: const InputDecoration(hintText: 'Email address', prefixIcon: Icon(Icons.email_outlined))),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _emailVerified = true);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification email sent'), behavior: SnackBarBehavior.floating),
                    );
                  },
                  child: Text(_emailVerified ? 'Update Email' : 'Send Verification Email'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoginSessionsSheet(BuildContext context) {
    final sessions = <Map<String, dynamic>>[
      {'device': 'Pixel 7 Pro', 'location': 'Nairobi, Kenya', 'time': 'Active now', 'current': true},
      {'device': 'Chrome on Windows', 'location': 'Nairobi, Kenya', 'time': '2 hours ago', 'current': false},
      {'device': 'Samsung Galaxy S23', 'location': 'Mombasa, Kenya', 'time': 'Yesterday 6:42 PM', 'current': false},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            _sheetHandle(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Login Sessions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              ),
            ),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: sessions.length,
                separatorBuilder: (context, i) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final s = sessions[i];
                  final isCurrent = s['current'] as bool;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.primarySurface : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isCurrent ? AppColors.primary.withValues(alpha:0.3) : AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          s['device']!.contains('Chrome') ? Icons.computer_outlined : Icons.smartphone_outlined,
                          color: isCurrent ? AppColors.primary : AppColors.textGrey,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(s['device']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('This device', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Colors.white)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text('${s['location']} · ${s['time']}', style: const TextStyle(fontSize: 11, color: AppColors.textGrey)),
                            ],
                          ),
                        ),
                        if (!isCurrent)
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(foregroundColor: AppColors.error, padding: EdgeInsets.zero, minimumSize: const Size(48, 32)),
                            child: const Text('End', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(feature, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text(
          '$feature is coming in a future update. We are working to bring you an even more secure Fundi-X experience.',
          style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.5),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: Size.zero, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)),
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }


  // ─── Support & Help actions ───────────────────────────────────────────────

  void _showHelpCenterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            _sheetHandle(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Align(alignment: Alignment.centerLeft, child: Text('Help Center', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark))),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _helpCategory(Icons.directions_car_outlined, 'Booking a Mechanic', 'Learn how to request service'),
                  _helpCategory(Icons.payments_outlined, 'Payments & Billing', 'Understand how payments work'),
                  _helpCategory(Icons.star_outline_rounded, 'Reviews & Ratings', 'How to rate your mechanic'),
                  _helpCategory(Icons.cancel_outlined, 'Cancellations', 'Cancellation policy and refunds'),
                  _helpCategory(Icons.account_circle_outlined, 'Account Management', 'Edit your profile and settings'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _helpCategory(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inactive, size: 18),
        ],
      ),
    );
  }

  void _showFAQsSheet(BuildContext context) {
    const faqs = [
      ('How do I request a mechanic?', 'Tap the "+" on the Home screen, describe your issue, confirm your location, and submit. We\'ll match you with a nearby mechanic.'),
      ('How is the service price determined?', 'Mechanics provide a quote based on your described issue. You approve the quote before any work begins.'),
      ('Can I track the mechanic?', 'Yes. Once a mechanic accepts your request, you can track their arrival in real time on the request screen.'),
      ('What if I\'m not satisfied with the service?', 'You can rate your mechanic after the job. For disputes, use "Report a Problem" in Settings.'),
      ('How do I cancel a request?', 'Open the active request and tap "Cancel". Cancellations are free before a mechanic is assigned.'),
      ('Is my payment secure?', 'Yes. All payments are processed securely. Fundi-X never stores your full card details.'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            _sheetHandle(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Align(alignment: Alignment.centerLeft, child: Text('Frequently Asked Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark))),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: faqs.length,
                itemBuilder: (_, i) => _FAQItem(question: faqs[i].$1, answer: faqs[i].$2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactSupportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sheetHandle(),
            const SizedBox(height: 8),
            const Text('Contact Support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 6),
            const Text('Our support team is available Mon–Sat, 8AM–8PM EAT.', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
            const SizedBox(height: 20),
            _contactOption(context, Icons.chat_bubble_outline_rounded, 'Live Chat', 'Typically replies in under 5 minutes'),
            const SizedBox(height: 10),
            _contactOption(context, Icons.email_outlined, 'Email Support', 'support@Fundi-X.co.ke'),
            const SizedBox(height: 10),
            _contactOption(context, Icons.phone_outlined, 'Call Us', '+254 800 123 456 (Toll-free)'),
          ],
        ),
      ),
    );
  }

  Widget _contactOption(BuildContext context, IconData icon, String title, String subtitle) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title — coming soon'), behavior: SnackBarBehavior.floating),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.inactive, size: 18),
          ],
        ),
      ),
    );
  }

  void _showReportProblemSheet(BuildContext context) {
    String selectedCategory = 'App Bug';
    final descCtrl = TextEditingController();
    const categories = ['App Bug', 'Payment Issue', 'Mechanic Complaint', 'Account Problem', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                const SizedBox(height: 8),
                const Text('Report a Problem', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 20),
                const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categories.map((c) {
                    final selected = c == selectedCategory;
                    return GestureDetector(
                      onTap: () => setSheetState(() => selectedCategory = c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.background,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
                        ),
                        child: Text(c, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.textDark)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Describe the problem in detail…'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Report submitted. We\'ll review it shortly.'), behavior: SnackBarBehavior.floating),
                      );
                    },
                    child: const Text('Submit Report'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLegalSheet(BuildContext context, {required String title, required String content}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            _sheetHandle(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: Text(content, style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.7)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared helpers ───────────────────────────────────────────────────────

  Widget _sheetHandle() => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 10, bottom: 4),
          width: 36,
          height: 4,
          decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
        ),
      );

  Widget _infoBox(IconData icon, String message, Color color) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha:0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: TextStyle(fontSize: 12, color: color, height: 1.4))),
          ],
        ),
      );
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.divider),
        ),
        child: Column(children: children),
      );
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({required this.icon, required this.label, required this.value, required this.onChanged, this.subtitle});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(icon, color: context.textGrey, size: 22),
        title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textDark)),
        subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(fontSize: 11, color: context.textLight)) : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? badge;
  final VoidCallback onTap;

  const _NavTile({required this.icon, required this.label, required this.onTap, this.value, this.badge});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(icon, color: context.textGrey, size: 22),
        title: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textDark)),
            if (badge != null) ...[const SizedBox(width: 8), badge!],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value != null) Text(value!, style: TextStyle(fontSize: 12, color: context.textGrey)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: context.inactive, size: 20),
          ],
        ),
        onTap: onTap,
      );
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: context.textGrey, size: 22),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textDark)),
      onTap: onTap,
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: AppColors.success.withValues(alpha:0.1), borderRadius: BorderRadius.circular(4)),
        child: const Text('Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)),
      );
}

class _UnverifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: AppColors.warning.withValues(alpha:0.1), borderRadius: BorderRadius.circular(4)),
        child: const Text('Unverified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warning)),
      );
}

class _ComingSoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(4)),
        child: const Text('Soon', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
      );
}

class _OptionSheetBody extends StatelessWidget {
  final String title;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;

  const _OptionSheetBody({required this.title, required this.options, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: context.divider, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Align(alignment: Alignment.centerLeft, child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textDark))),
          ),
          ...options.map((opt) {
            final isSelected = opt == selected;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Text(opt, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, color: isSelected ? AppColors.primary : context.textDark)),
              trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18) : null,
              onTap: () => onSelected(opt),
            );
          }),
          const SizedBox(height: 16),
        ],
      );
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;
  const _FAQItem({required this.question, required this.answer});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _expanded ? AppColors.primary.withValues(alpha:0.3) : AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(widget.question, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark))),
                  Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.textGrey, size: 20),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 8),
                Text(widget.answer, style: const TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.6)),
              ],
            ],
          ),
        ),
      );
}

// ─── Legal mock content ───────────────────────────────────────────────────────

const _termsContent = '''
Last updated: May 2026

1. Acceptance of Terms
By using the Fundi-X platform, you agree to these Terms & Conditions in full. If you disagree with any part, you may not use our services.

2. Services
Fundi-X connects vehicle owners with independent mechanics. We act as a marketplace and are not directly responsible for the quality of mechanical services provided by independent mechanics on our platform.

3. User Accounts
You are responsible for maintaining the confidentiality of your account credentials. You agree to notify Fundi-X immediately of any unauthorized use of your account.

4. Payments
All payments are processed securely through our platform. Service prices are set by mechanics and agreed upon by customers before work begins. Fundi-X charges a platform fee on each transaction.

5. Cancellations
Cancellations made before a mechanic is assigned are free of charge. Cancellations after assignment may incur a fee as outlined in our cancellation policy.

6. Liability
Fundi-X is not liable for any direct, indirect, incidental, or consequential damages arising from the use of our platform or the services provided by mechanics.

7. Changes to Terms
We reserve the right to modify these terms at any time. Continued use of the platform after changes constitutes acceptance of the new terms.

8. Governing Law
These terms are governed by the laws of the Republic of Kenya.

Contact: legal@Fundi-X.co.ke
''';

const _privacyContent = '''
Last updated: May 2026

1. Information We Collect
We collect information you provide directly (name, email, phone number, location) and information generated by your use of our platform (request history, location data, device information).

2. How We Use Your Information
Your information is used to provide and improve our services, match you with mechanics, process payments, send notifications, and ensure platform safety.

3. Location Data
We collect location data to connect you with nearby mechanics and provide accurate arrival times. You can manage location permissions through your device settings.

4. Data Sharing
We share your information with mechanics only as necessary to fulfill your service requests. We do not sell your personal data to third parties.

5. Data Security
We use industry-standard encryption and security practices to protect your information. However, no system is completely secure and we cannot guarantee absolute security.

6. Data Retention
We retain your account data for as long as your account is active. You may request deletion of your account and associated data at any time.

7. Your Rights
You have the right to access, correct, or delete your personal data. To exercise these rights, contact us at privacy@Fundi-X.co.ke.

8. Cookies
Our mobile application does not use cookies but may use similar tracking technologies to improve your experience.

9. Children's Privacy
Fundi-X is not intended for users under 18 years of age. We do not knowingly collect data from minors.

10. Contact
For privacy concerns: privacy@Fundi-X.co.ke
''';
