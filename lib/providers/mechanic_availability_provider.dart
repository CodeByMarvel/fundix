import 'package:flutter_riverpod/flutter_riverpod.dart';

// Tracks whether the mechanic is accepting new jobs.
// Separate from JobState so toggling online/offline doesn't affect the job lifecycle.
final mechanicIsOnlineProvider = StateProvider<bool>((ref) => false);

// Active tab index for MechanicShell (0=Dashboard, 1=Jobs, 2=Earnings, 3=Profile).
// Written by the dashboard banner to navigate without a direct callback.
final mechanicShellIndexProvider = StateProvider<int>((ref) => 0);

// Which sub-tab inside JobsScreen should be shown (0=Incoming, 1=Active).
// Written alongside mechanicShellIndexProvider so the banner can deep-link into the correct tab.
final mechanicJobsTabIndexProvider = StateProvider<int>((ref) => 0);
