import 'package:flutter/foundation.dart';

@immutable
class Vehicle {
  final String id;
  final String brand;
  final String model;
  final int year;
  final String? engine;
  final String fuelType;       // Petrol, Diesel, Electric, Hybrid
  final String transmission;   // Auto, Manual
  final String bodyType;       // Sedan, Touring, Coupe, SUV, Hatchback, Pickup, Van, Minivan
  final String? plateNumber;
  final String? nickname;

  const Vehicle({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    this.engine,
    required this.fuelType,
    required this.transmission,
    required this.bodyType,
    this.plateNumber,
    this.nickname,
  });

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] as String,
        brand: j['brand'] as String,
        model: j['model'] as String,
        year: j['year'] as int,
        engine: j['engine'] as String?,
        fuelType: j['fuel_type'] as String? ?? 'Petrol',
        transmission: j['transmission'] as String? ?? 'Auto',
        bodyType: j['body_type'] as String? ?? 'Sedan',
        plateNumber: j['plate_number'] as String?,
        nickname: j['nickname'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'brand': brand,
        'model': model,
        'year': year,
        if (engine != null) 'engine': engine,
        'fuel_type': fuelType,
        'transmission': transmission,
        'body_type': bodyType,
        if (plateNumber != null) 'plate_number': plateNumber,
        if (nickname != null) 'nickname': nickname,
      };

  String get displayName => nickname ?? '$year $brand $model';

  String get subtitle =>
      <String?>[engine, fuelType, transmission, bodyType].nonNulls.join(' · ');

  static const List<String> bodyTypes = [
    'Sedan',
    'Touring',
    'Coupe',
    'SUV',
    'Hatchback',
    'Pickup',
    'Van',
    'Minivan',
    'Convertible',
    'Wagon',
  ];

  static const List<String> fuelTypes = [
    'Petrol',
    'Diesel',
    'Electric',
    'Hybrid',
  ];

  static const List<String> transmissionTypes = [
    'Auto',
    'Manual',
  ];
}
