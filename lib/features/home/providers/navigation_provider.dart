import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider holding the currently selected bottom navigation tab index:
/// 0: Home (Dashboard)
/// 1: Transactions
/// 2: Budget
/// 3: Udhaar
final navigationIndexProvider = StateProvider<int>((ref) => 0);
