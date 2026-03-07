// --- Data Model ---
class PointLedgerBatch {
  final int ledgerId;
  final String stationName;
  final String fuelType;
  final int earnedPoints;
  final int remainingPoints;
  final int usedPoints;
  final DateTime expiresAt;
  final DateTime earnedAt;
  final int daysUntilExpiry;
  final String status; // 'EXPIRED', 'EXPIRING_SOON', 'ACTIVE'

  PointLedgerBatch({
    required this.ledgerId,
    required this.stationName,
    required this.fuelType,
    required this.earnedPoints,
    required this.remainingPoints,
    required this.usedPoints,
    required this.expiresAt,
    required this.earnedAt,
    required this.daysUntilExpiry,
    required this.status,
  });

  factory PointLedgerBatch.fromMap(Map<String, dynamic> map) {
    return PointLedgerBatch(
      ledgerId: map['ledger_id'],
      stationName: map['station_name'] ?? 'Unknown Station',
      fuelType: map['fuel_type'] ?? 'Fuel',
      earnedPoints: map['earned_points'],
      remainingPoints: map['remaining_points'],
      usedPoints: map['used_points'],
      expiresAt: DateTime.parse(map['expires_at']),
      earnedAt: DateTime.parse(map['earned_at']),
      daysUntilExpiry: map['days_until_expiry'],
      status: map['status'],
    );
  }
}
