enum RelocationStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  static RelocationStatus fromString(String value) {
    return switch (value) {
      'PENDING'     => RelocationStatus.pending,
      'IN_PROGRESS' => RelocationStatus.inProgress,
      'COMPLETED'   => RelocationStatus.completed,
      'CANCELLED'   => RelocationStatus.cancelled,
      _             => throw ArgumentError('Unknown status: $value'),
    };
  }
}

class Relocation {
  const Relocation({
    required this.id,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String vehicleMake;
  final String vehicleModel;
  final String pickupLocation;
  final String dropoffLocation;
  final RelocationStatus status;
  final DateTime createdAt;

  factory Relocation.fromJson(Map<String, dynamic> json) {
    return Relocation(
      id: json['id'] as String,
      vehicleMake: json['vehicle_make'] as String,
      vehicleModel: json['vehicle_model'] as String,
      pickupLocation: json['pickup_location'] as String,
      dropoffLocation: json['dropoff_location'] as String,
      status: RelocationStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
