import 'package:flutter_riverpod/flutter_riverpod.dart';

// Tracks whether the mechanic is accepting new jobs.
// Separate from JobState so toggling online/offline doesn't affect the job lifecycle.
final mechanicIsOnlineProvider = StateProvider<bool>((ref) => false);
