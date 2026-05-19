import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class EarningsTransaction {
  final String id;
  final DateTime completedAt;
  final double amount;
  final String category;

  const EarningsTransaction({
    required this.id,
    required this.completedAt,
    required this.amount,
    required this.category,
  });
}

@immutable
class EarningsState {
  final List<EarningsTransaction> transactions;

  const EarningsState({this.transactions = const []});

  DateTime get _todayStart {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime get _weekStart {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day - (n.weekday - 1));
  }

  DateTime get _monthStart {
    final n = DateTime.now();
    return DateTime(n.year, n.month, 1);
  }

  List<EarningsTransaction> _since(DateTime start) =>
      transactions.where((t) => !t.completedAt.isBefore(start)).toList();

  List<EarningsTransaction> get today => _since(_todayStart);
  List<EarningsTransaction> get thisWeek => _since(_weekStart);
  List<EarningsTransaction> get thisMonth => _since(_monthStart);

  double totalFor(List<EarningsTransaction> txs) =>
      txs.fold(0.0, (sum, t) => sum + t.amount);

  double get totalToday => totalFor(today);
  double get totalThisWeek => totalFor(thisWeek);
  double get totalThisMonth => totalFor(thisMonth);

  int get jobsToday => today.length;

  EarningsState copyWith({List<EarningsTransaction>? transactions}) =>
      EarningsState(transactions: transactions ?? this.transactions);
}

class EarningsNotifier extends StateNotifier<EarningsState> {
  EarningsNotifier() : super(const EarningsState());

  void recordJob({required double amount, required String category}) {
    final tx = EarningsTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      completedAt: DateTime.now(),
      amount: amount,
      category: category,
    );
    state = state.copyWith(
      transactions: [...state.transactions, tx],
    );
  }
}

final earningsProvider =
    StateNotifierProvider<EarningsNotifier, EarningsState>(
  (_) => EarningsNotifier(),
);
