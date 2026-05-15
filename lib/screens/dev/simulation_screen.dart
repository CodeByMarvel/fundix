import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_colors.dart';
import '../../services/simulation_service.dart';
import '../shell/main_shell.dart';
import '../mechanic/shell/mechanic_shell.dart';

class SimulationScreen extends ConsumerStatefulWidget {
  const SimulationScreen({super.key});

  @override
  ConsumerState<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends ConsumerState<SimulationScreen> {
  int _view = 0; // 0 = customer, 1 = mechanic
  bool _running = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (_running) return;
    setState(() => _running = true);
    SimulationService.runFullJob(ref).whenComplete(() {
      if (mounted) setState(() => _running = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(simulationStatusProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Column(
          children: [
            _SimHeader(
              status: status,
              isRunning: _running,
              activeView: _view,
              onToggle: (v) => setState(() => _view = v),
              onBack: () => Navigator.of(context).pop(),
              onRestart: _running ? null : _start,
            ),
            Expanded(
              child: IndexedStack(
                index: _view,
                children: const [
                  MainShell(),
                  MechanicShell(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SimHeader extends StatelessWidget {
  const _SimHeader({
    required this.status,
    required this.isRunning,
    required this.activeView,
    required this.onToggle,
    required this.onBack,
    this.onRestart,
  });

  final String status;
  final bool isRunning;
  final int activeView;
  final ValueChanged<int> onToggle;
  final VoidCallback onBack;
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0F1A),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Column(
        children: [
          // title row
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: onBack,
              ),
              const Expanded(
                child: Text(
                  'SIMULATION',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              if (onRestart != null)
                IconButton(
                  icon: const Icon(
                    Icons.replay_rounded,
                    color: Colors.white60,
                    size: 20,
                  ),
                  onPressed: onRestart,
                  tooltip: 'Restart simulation',
                ),
            ],
          ),

          // status strip
          if (status.isNotEmpty)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: isRunning
                    ? AppColors.primary.withValues(alpha: 0.08)
                    : AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isRunning
                      ? AppColors.primary.withValues(alpha: 0.25)
                      : AppColors.success.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  if (isRunning)
                    const SizedBox(
                      width: 11,
                      height: 11,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.primary,
                      ),
                    )
                  else
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 13,
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        color: isRunning ? AppColors.primary : AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // view toggle
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _Toggle(
                  label: 'CUSTOMER',
                  icon: Icons.directions_car_rounded,
                  isSelected: activeView == 0,
                  onTap: () => onToggle(0),
                ),
                _Toggle(
                  label: 'MECHANIC',
                  icon: Icons.handyman_rounded,
                  isSelected: activeView == 1,
                  onTap: () => onToggle(1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
