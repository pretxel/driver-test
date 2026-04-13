import 'package:flutter_test/flutter_test.dart';
import 'package:flovi_driver/core/models/relocation.dart';

void main() {
  group('Relocation', () {
    final json = {
      'id': 'cmnw45v3c00005dulztca8of0',
      'origin': 'Madrid',
      'destination': 'Valencia',
      'date': '2026-04-20T10:00:00',
      'notes': null,
      'status': 'PENDING',
      'userId': 'bc3b1863-3c22-444d-b95a-070c4f8fb675',
      'createdAt': '2026-04-12T18:45:13.513',
      'updatedAt': '2026-04-12T18:45:13.513',
    };

    test('fromJson parses all fields correctly', () {
      final r = Relocation.fromJson(json);
      expect(r.id, 'cmnw45v3c00005dulztca8of0');
      expect(r.origin, 'Madrid');
      expect(r.destination, 'Valencia');
      expect(r.date, DateTime.parse('2026-04-20T10:00:00'));
      expect(r.notes, isNull);
      expect(r.status, RelocationStatus.pending);
      expect(r.createdAt, DateTime.parse('2026-04-12T18:45:13.513'));
    });

    test('fromJson parses notes when present', () {
      final r = Relocation.fromJson({...json, 'notes': 'Handle with care'});
      expect(r.notes, 'Handle with care');
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
