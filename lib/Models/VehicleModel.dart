class VehicleModel {
  final String id;
  final String userId;
  final String licensePlate;
  final String? brand;
  final String? model;
  final DateTime? lastOilChangeDate;
  final DateTime? insuranceExpiryDate;
  final DateTime createdAt;

  VehicleModel({
    required this.id,
    required this.userId,
    required this.licensePlate,
    this.brand,
    this.model,
    this.lastOilChangeDate,
    this.insuranceExpiryDate,
    required this.createdAt,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'],
      userId: json['user_id'],
      licensePlate: json['license_plate'],
      brand: json['brand'],
      model: json['model'],
      lastOilChangeDate: json['last_oil_change_date'] != null
          ? DateTime.parse(json['last_oil_change_date'])
          : null,
      insuranceExpiryDate: json['insurance_expiry_date'] != null
          ? DateTime.parse(json['insurance_expiry_date'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'license_plate': licensePlate,
      'brand': brand,
      'model': model,
      'last_oil_change_date': lastOilChangeDate?.toIso8601String().split('T')[0],
      'insurance_expiry_date': insuranceExpiryDate?.toIso8601String().split('T')[0],
    };
  }
}
