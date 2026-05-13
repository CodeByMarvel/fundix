import 'package:flutter/foundation.dart';

enum UserRole { customer, mechanic }

@immutable
class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
}

// Mock users used throughout development
class MockUsers {
  static const customer = AppUser(
    id: 'cust_001',
    name: 'Alex Kamau',
    email: 'alex@example.com',
    role: UserRole.customer,
  );

  static const mechanic = AppUser(
    id: 'mech_001',
    name: 'John Mwangi',
    email: 'john@example.com',
    role: UserRole.mechanic,
  );
}
