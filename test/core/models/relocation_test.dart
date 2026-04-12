import 'package:flutter_test/flutter_test.dart';
import 'package:flovi_driver/core/models/relocation.dart';

void main() {
  group('Relocation', () {
    final json = {
      'id': 'abc-123',
      'vehicle_make': 'Ford',
      'vehicle_model': 'Focus',
      'pickup_location': 'Main Depot',
      'dropoff_location': 'Airport T1',
      'status': 'PENDING',
      'created_at': '2026-04-12T10:00:00.000Z',
    };

    test('fromJson parses all fields correctly', () {
      final r = Relocation.fromJson(json);
      expect(r.id, 'abc-123');
      expect(r.vehicleMake, 'Ford');
      expect(r.vehicleModel, 'Focus');
      expect(r.pickupLocation, 'Main Depot');
      expect(r.dropoffLocation, 'Airport T1');
      expect(r.status, RelocationStatus.pending);
      expect(r.createdAt, DateTime.parse('2026-04-12T10:00:00.000Z'));
    });

    test('fromJson maps IN_PROGRESS status', () {
      final r = Relocation.fromJson({...json, 'status': 'IN_PROGRESS'});
      expect(r.status, RelocationStatus.inProgress);
    });

    test('fromJson maps COMPLETED status', () {
      final r = Relocation.fromJson({...json, 'status': 'COMPLETED'});
      expect(r.status, RelocationStatus.completed);
    });

    test('fromJson maps CANCELLED status', () {
      final r = Relocation.fromJson({...json, 'status': 'CANCELLED'});
      expect(r.status, RelocationStatus.cancelled);
    });

    test('fromJson throws on unknown status', () {
      expect(
        () => Relocation.fromJson({...json, 'status': 'UNKNOWN'}),
        throwsArgumentError,
      );
    });
  });
}
