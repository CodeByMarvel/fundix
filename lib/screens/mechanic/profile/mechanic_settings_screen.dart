import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_theme_ext.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/locale_provider.dart';

class MechanicSettingsScreen extends ConsumerStatefulWidget {
  const MechanicSettingsScreen({super.key});

  @override
  ConsumerState<MechanicSettingsScreen> createState() => _MechanicSettingsScreenState();
}

class _MechanicSettingsScreenState extends ConsumerState<MechanicSettingsScreen> {
  // Work Preferences
  bool _isOnline = true;
  bool _emergencyJobs = false;
  String _workStart = '08:00 AM';
  String _workEnd = '06:00 PM';

  // Notifications
  bool _newJobRequests = true;
  bool _customerMessages = true;
  bool _paymentNotifications = true;
  bool _jobStatusReminders = true;
  bool _systemAnnouncements = true;
  bool _promotionalNotifications = false;

  // Account
  bool _phoneVerified = true;
  bool _emailVerified = false;

  // Verification
  bool _nationalIdVerified = false;
  bool _certificationUploaded = false;
  bool _businessRegistered = false;

  // App Preferences
  String _dataUsage = 'Standard';

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
          _sectionLabel('Work Preferences'),
          _SettingsCard(children: [
            _ToggleTile(
              icon: _isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              label: 'Availability',
              subtitle: _isOnline ? 'Online — visible to customers' : 'Offline — not accepting jobs',
              value: _isOnline,
              activeColor: AppColors.success,
              onChanged: (v) => setState(() => _isOnline = v),
            ),
            _divider(),
            _NavTile(
              icon: Icons.schedule_outlined,
              label: 'Working Hours',
              value: '$_workStart – $_workEnd',
              onTap: () => _showWorkingHoursSheet(context),
            ),
            _divider(),
            _ToggleTile(
              icon: Icons.bolt_outlined,
              label: 'Emergency Job Availability',
              subtitle: 'Accept urgent requests outside working hours',
              value: _emergencyJobs,
              onChanged: (v) => setState(() => _emergencyJobs = v),
            ),
          ]),
          const SizedBox(height: 20),
          _sectionLabel('Notifications'),
          _SettingsCard(children: [
            _ToggleTile(
              icon: Icons.work_outline_rounded,
              label: 'New Job Requests',
              value: _newJobRequests,
              onChanged: (v) => setState(() => _newJobRequests = v),
            ),
            _divider(),
            _ToggleTile(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Customer Messages',
              value: _customerMessages,
              onChanged: (v) => setState(() => _customerMessages = v),
            ),
            _divider(),
            _ToggleTile(
              icon: Icons.receipt_outlined,
              label: 'Payment Notifications',
              value: _paymentNotifications,
              onChanged: (v) => setState(() => _paymentNotifications = v),
            ),
            _divider(),
            _ToggleTile(
              icon: Icons.notifications_active_outlined,
              label: 'Job Status Reminders',
              value: _jobStatusReminders,
              onChanged: (v) => setState(() => _jobStatusReminders = v),
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
              subtitle: 'Occasional platform updates and opportunities',
              value: _promotionalNotifications,
              onChanged: (v) => setState(() => _promotionalNotifications = v),
            ),
          ]),
          const SizedBox(height: 20),
          _sectionLabel('Location & Coverage'),
          _SettingsCard(children: [
            _NavTile(
              icon: Icons.store_outlined,
              label: 'Current Workshop Location',
              onTap: () => _showWorkshopLocationSheet(context),
            ),
            _divider(),
            _NavTile(
              icon: Icons.gps_fixed_outlined,
              label: 'GPS / Location Permissions',
              onTap: () => _showLocationPermissionsDialog(context),
            ),
            _divider(),
            _NavTile(
              icon: Icons.bookmark_outline_rounded,
              label: 'Saved Work Location',
              onTap: () => _showSavedWorkLocationSheet(context),
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
          _sectionLabel('Verification & Professional Information'),
          _SettingsCard(children: [
            _NavTile(
              icon: Icons.badge_outlined,
              label: 'National ID Verification',
              badge: _nationalIdVerified ? _VerifiedBadge() : _UnverifiedBadge(),
              onTap: () => _showVerificationSheet(
                context,
                title: 'National ID Verification',
                description: 'Upload a clear photo of the front and back of your national ID card.',
                isVerified: _nationalIdVerified,
                onSubmit: () => setState(() => _nationalIdVerified = true),
              ),
            ),
            _divider(),
            _NavTile(
              icon: Icons.workspace_premium_outlined,
              label: 'Mechanic Certification',
              badge: _certificationUploaded ? _VerifiedBadge() : _PendingBadge(),
              onTap: () => _showVerificationSheet(
                context,
                title: 'Mechanic Certification',
                description: 'Upload your mechanic certification or relevant trade certificate to build customer trust.',
                isVerified: _certificationUploaded,
                onSubmit: () => setState(() => _certificationUploaded = true),
              ),
            ),
            _divider(),
            _NavTile(
              icon: Icons.business_outlined,
              label: 'Garage / Business Registration',
              badge: _businessRegistered ? _VerifiedBadge() : _PendingBadge(),
              onTap: () => _showVerificationSheet(
                context,
                title: 'Garage / Business Registration',
                description: 'Upload your business registration certificate if you operate a registered garage.',
                isVerified: _businessRegistered,
                onSubmit: () => setState(() => _businessRegistered = true),
              ),
            ),
            _divider(),
            _NavTile(
              icon: Icons.verified_outlined,
              label: 'Verification Status',
              badge: (_nationalIdVerified && _certificationUploaded)
                  ? _VerifiedBadge()
                  : _PendingBadge(),
              onTap: () => _showVerificationStatusSheet(context),
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
              icon: Icons.menu_book_outlined,
              label: 'Mechanic Guidelines',
              onTap: () => _showMechanicGuidelinesSheet(context),
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
          const SizedBox(height: 20),
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
        ],
      ),
    );
  }

  // ─── Section helpers ──────────────────────────────────────────────────────

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

  // ─── Work Preferences ─────────────────────────────────────────────────────

  void _showWorkingHoursSheet(BuildContext context) {
    const hourOptions = [
      '06:00 AM', '07:00 AM', '08:00 AM', '09:00 AM', '10:00 AM',
      '12:00 PM', '02:00 PM', '04:00 PM', '05:00 PM', '06:00 PM',
      '07:00 PM', '08:00 PM',
    ];
    String tempStart = _workStart;
    String tempEnd = _workEnd;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHandle(),
              const SizedBox(height: 8),
              const Text('Working Hours', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
                        const SizedBox(height: 8),
                        _TimeDropdown(
                          value: tempStart,
                          options: hourOptions,
                          onChanged: (v) => setSheetState(() => tempStart = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textGrey)),
                        const SizedBox(height: 8),
                        _TimeDropdown(
                          value: tempEnd,
                          options: hourOptions,
                          onChanged: (v) => setSheetState(() => tempEnd = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _workStart = tempStart;
                      _workEnd = tempEnd;
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Working hours updated'), behavior: SnackBarBehavior.floating),
                    );
                  },
                  child: const Text('Save Hours'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Location & Coverage ──────────────────────────────────────────────────

  void _showWorkshopLocationSheet(BuildContext context) {
    final ctrl = TextEditingController(text: 'Industrial Area, Nairobi');
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
              const Text('Workshop Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 6),
              const Text('This is shown to customers as your base of operations.', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(
                  hintText: 'Enter workshop address',
                  prefixIcon: Icon(Icons.store_outlined),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Workshop location saved'), behavior: SnackBarBehavior.floating),
                    );
                  },
                  child: const Text('Save Location'),
                ),
              ),
            ],
          ),
        ),
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
          'Fundix uses your location to connect you with nearby customers and show accurate distances.\n\nTo manage location permissions, go to your device Settings → Apps → Fundix → Permissions.',
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

  void _showSavedWorkLocationSheet(BuildContext context) {
    final savedLocations = <Map<String, String>>[
      {'label': 'Main Workshop', 'address': 'Industrial Area, Nairobi'},
      {'label': 'Secondary Garage', 'address': 'Westlands, Nairobi'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                    const Text('Saved Work Locations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: savedLocations.length,
                  separatorBuilder: (context, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final loc = savedLocations[i];
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
                                Text(loc['label']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                                const SizedBox(height: 2),
                                Text(loc['address']!, style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 18),
                            onPressed: () => setSheetState(() => savedLocations.removeAt(i)),
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

  // ─── Account & Security ───────────────────────────────────────────────────

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
    final emailCtrl = TextEditingController(text: 'mechanic@email.com');
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
      {'device': 'Chrome on Windows', 'location': 'Nairobi, Kenya', 'time': '3 hours ago', 'current': false},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
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
                separatorBuilder: (context, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final s = sessions[i];
                  final isCurrent = s['current'] as bool;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.primarySurface : AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isCurrent ? AppColors.primary.withValues(alpha: 0.3) : AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          s['device'].toString().contains('Chrome') ? Icons.computer_outlined : Icons.smartphone_outlined,
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
          '$feature is coming in a future update. We are working to bring you an even more secure Fundix experience.',
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

  // ─── Verification & Professional Information ──────────────────────────────

  void _showVerificationSheet(
    BuildContext context, {
    required String title,
    required String description,
    required bool isVerified,
    required VoidCallback onSubmit,
  }) {
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
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 12),
              if (isVerified)
                _infoBox(Icons.check_circle_outline, 'This document has been verified.', AppColors.success)
              else
                _infoBox(Icons.info_outline, description, AppColors.primary),
              const SizedBox(height: 20),
              if (!isVerified) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.upload_file_outlined, size: 32, color: AppColors.textLight),
                      const SizedBox(height: 8),
                      const Text('Tap to upload document', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
                      const SizedBox(height: 4),
                      const Text('JPG, PNG or PDF — max 10MB', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      onSubmit();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$title submitted for review'), behavior: SnackBarBehavior.floating),
                      );
                    },
                    child: const Text('Submit for Verification'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showVerificationStatusSheet(BuildContext context) {
    final checks = [
      ('National ID', _nationalIdVerified),
      ('Mechanic Certification', _certificationUploaded),
      ('Business Registration', _businessRegistered),
    ];

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
            const Text('Verification Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 6),
            const Text('Complete all verifications to build trust with customers.', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
            const SizedBox(height: 20),
            ...checks.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.$2 ? AppColors.success.withValues(alpha: 0.06) : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.$2 ? AppColors.success.withValues(alpha: 0.3) : AppColors.divider),
                ),
                child: Row(
                  children: [
                    Icon(
                      c.$2 ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      color: c.$2 ? AppColors.success : AppColors.inactive,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(c.$1, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: c.$2 ? AppColors.textDark : AppColors.textGrey)),
                    const Spacer(),
                    Text(
                      c.$2 ? 'Verified' : 'Pending',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c.$2 ? AppColors.success : AppColors.warning),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  // ─── Support & Help ───────────────────────────────────────────────────────

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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Help Center', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _helpCategory(Icons.work_outline_rounded, 'Managing Job Requests', 'Accept, decline, and manage jobs'),
                  _helpCategory(Icons.payments_outlined, 'Payments & Payouts', 'How earnings and payouts work'),
                  _helpCategory(Icons.star_outline_rounded, 'Ratings & Reviews', 'How the rating system works'),
                  _helpCategory(Icons.cancel_outlined, 'Cancellations', 'Cancellation policy for mechanics'),
                  _helpCategory(Icons.verified_outlined, 'Getting Verified', 'How to complete your verification'),
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

  void _showMechanicGuidelinesSheet(BuildContext context) {
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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Mechanic Guidelines', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: const Text(_mechanicGuidelinesContent, style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.7)),
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
            const Text('Our mechanic support team is available Mon–Sat, 7AM–9PM EAT.', style: TextStyle(fontSize: 13, color: AppColors.textGrey)),
            const SizedBox(height: 20),
            _contactOption(context, Icons.chat_bubble_outline_rounded, 'Live Chat', 'Typically replies in under 5 minutes'),
            const SizedBox(height: 10),
            _contactOption(context, Icons.email_outlined, 'Email Support', 'mechanics@fundix.co.ke'),
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
    const categories = ['App Bug', 'Payment Issue', 'Customer Complaint', 'Account Problem', 'Other'];

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

  // ─── App Preferences ──────────────────────────────────────────────────────

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
          'This will clear all locally stored images and temporary data. Your account and job history will not be affected.',
          style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully'), behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
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
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
  final Color? activeColor;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(icon, color: context.textGrey, size: 22),
        title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: context.textDark)),
        subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(fontSize: 11, color: context.textLight)) : null,
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: activeColor ?? AppColors.primary,
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
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppColors.error : context.textDark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(icon, color: isDestructive ? AppColors.error : context.textGrey, size: 22),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
      onTap: onTap,
    );
  }
}

class _TimeDropdown extends StatelessWidget {
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _TimeDropdown({required this.value, required this.options, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.divider),
        ),
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: const SizedBox(),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textDark),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      );
}

class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
        child: const Text('Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.success)),
      );
}

class _UnverifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: AppColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
        child: const Text('Unverified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warning)),
      );
}

class _PendingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(4)),
        child: const Text('Pending', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
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
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.textDark)),
            ),
          ),
          ...options.map((opt) {
            final isSelected = opt == selected;
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              title: Text(
                opt,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : context.textDark,
                ),
              ),
              trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.primary, size: 18) : null,
              onTap: () => onSelected(opt),
            );
          }),
          const SizedBox(height: 16),
        ],
      );
}

// ─── Legal & Guidelines content ───────────────────────────────────────────────

const _mechanicGuidelinesContent = '''
Last updated: May 2026

1. Professional Conduct
Always maintain a professional and respectful attitude with customers. Your behavior reflects on the entire Fundix platform.

2. Accurate Job Descriptions
Provide honest and accurate assessments of vehicle issues. Never inflate diagnoses or recommend unnecessary repairs.

3. Pricing Transparency
Always provide a clear quote before starting work. Do not charge more than the agreed amount without prior customer approval.

4. Timely Response
Respond to job requests within 5 minutes of receiving them. Consistently ignoring requests may affect your visibility on the platform.

5. Punctuality
Arrive within the estimated time you provide to customers. If you are delayed, communicate promptly through the app.

6. Quality of Work
Deliver high-quality repairs that meet industry standards. Shoddy work that leads to customer complaints may result in account suspension.

7. Safety Standards
Always follow proper safety protocols when working on vehicles. Never perform work that could endanger the customer or their property.

8. Document Handling
Keep your verification documents up to date. Expired documents will result in reduced platform visibility.

9. Payment Processing
All payments must be processed through the Fundix platform. Off-platform payments are a violation of our terms of service.

10. Platform Integrity
Do not attempt to take customer relationships off-platform. This protects both you and the customer.

For questions: mechanics@fundix.co.ke
''';

const _termsContent = '''
Last updated: May 2026

1. Acceptance of Terms
By using the Fundix platform as a mechanic, you agree to these Terms & Conditions in full. If you disagree with any part, you may not use our services.

2. Services
Fundix connects vehicle owners with independent mechanics. You operate as an independent service provider, not an employee of Fundix.

3. Account Requirements
You must maintain valid verification documents and comply with all professional requirements to remain active on the platform.

4. Payments & Commissions
Fundix processes all customer payments and remits your earnings minus the platform commission. Rates are outlined in the Mechanic Agreement.

5. Cancellations
Excessive cancellations negatively impact your platform rating and may result in account restrictions.

6. Liability
You are solely responsible for the quality of mechanical services you provide. Fundix is not liable for damages arising from your work.

7. Governing Law
These terms are governed by the laws of the Republic of Kenya.

Contact: legal@fundix.co.ke
''';

const _privacyContent = '''
Last updated: May 2026

1. Information We Collect
We collect your professional information (name, ID, certifications), contact details, location data, and job activity records.

2. How We Use Your Information
Your information is used to match you with customers, process payments, display your profile, and ensure platform integrity.

3. Location Data
We collect location data while you are set to Online to connect you with nearby customers. You can go Offline at any time to stop location sharing.

4. Data Sharing
We share your name, ratings, and skills with customers seeking services. We do not sell your personal data to third parties.

5. Data Security
We use industry-standard encryption to protect your information and earnings data.

6. Your Rights
You may request access to, correction of, or deletion of your personal data by contacting privacy@fundix.co.ke.

10. Contact
For privacy concerns: privacy@fundix.co.ke
''';
