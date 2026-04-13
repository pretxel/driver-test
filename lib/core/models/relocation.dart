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
    required this.origin,
    required this.destination,
    required this.date,
    this.notes,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String origin;
  final String destination;
  final DateTime date;
  final String? notes;
  final RelocationStatus status;
  final DateTime createdAt;

  factory Relocation.fromJson(Map<String, dynamic> json) {
    return Relocation(
      id: json['id'] as String,
      origin: json['origin'] as String,
      destination: json['destination'] as String,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String?,
      status: RelocationStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
