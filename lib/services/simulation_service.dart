import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/job_notifier.dart';
import '../providers/mechanic_availability_provider.dart';

final simulationStatusProvider = StateProvider<String>((ref) => '');

class SimulationService {
  static const _description =
      'Engine warning light on, car shaking at idle. '
      'Knocking sound when accelerating. Started 3 days ago, getting worse.';

  static Future<void> runFullJob(WidgetRef ref) async {
    final notifier = ref.read(jobProvider.notifier);
    notifier.reset();
    ref.read(mechanicIsOnlineProvider.notifier).state = true;

    void status(String msg) =>
        ref.read(simulationStatusProvider.notifier).state = msg;

    await Future.delayed(const Duration(milliseconds: 400));

    // Stage 1 — customer submits request
    status('Customer submitting request…');
    await notifier.submitRequest(
      description: _description,
      carType: '2012 Toyota Premio',
      location: 'Westlands, Nairobi',
      manualCategory: 'Engine',
    );

    // submitRequest awaits its 2s search internally — now state = mechanicsResponding
    status('Finding nearby mechanics…');
    await Future.delayed(const Duration(seconds: 1));

    // Stage 2 — pick best mechanic (don't wait 15s auto-assign)
    final offers = ref.read(jobProvider).pendingOffers;
    if (offers.isEmpty) return;
    final best = offers.first;
    status('Customer selected ${best.name}');
    notifier.selectMechanic(best);

    // selectMechanic triggers mechanicAcceptsJob() internally after 2s — wait 3s
    await Future.delayed(const Duration(seconds: 3));
    status('${best.name} accepted · En route (${best.etaMinutes} min ETA)');

    // Stage 3 — mechanic drives there
    await Future.delayed(const Duration(seconds: 4));
    status('${best.name} arrived at location');
    notifier.mechanicArrived();

    await Future.delayed(const Duration(seconds: 2));
    status('Customer confirmed mechanic arrival');
    notifier.customerConfirmsArrival();

    await Future.delayed(const Duration(seconds: 2));
    status('Mechanic starting service…');
    notifier.mechanicStartsService();

    // Stage 4 — dual-confirm start
    await Future.delayed(const Duration(seconds: 2));
    status('Customer confirmed service start · Work underway');
    notifier.customerConfirmsStart();

    // Stage 5 — service active
    await Future.delayed(const Duration(seconds: 5));

    // Stage 6 — work proof
    status('Mechanic submitting work proof…');
    notifier.mechanicSubmitsWorkProof(
      note: 'Replaced ignition coils, cleaned throttle body. '
          'Cleared engine codes. Test drive confirmed fix.',
      checklistConfirmed: true,
    );

    // Stage 7 — dual-confirm end
    await Future.delayed(const Duration(seconds: 2));
    status('Mechanic ending service');
    notifier.mechanicEndsService();

    await Future.delayed(const Duration(seconds: 3));
    status('Customer confirmed work complete');
    notifier.customerConfirmsCompletion();

    // Stage 8 — review
    await Future.delayed(const Duration(seconds: 2));
    status('Customer leaving review…');
    notifier.submitReview(
      stars: 5,
      issueResolved: true,
      wasProfessional: true,
      comment: '${best.name} was fast and professional. Issue fully resolved!',
    );

    status('Simulation complete');
  }
}
