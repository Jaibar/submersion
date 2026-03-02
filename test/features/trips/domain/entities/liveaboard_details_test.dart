import 'package:flutter_test/flutter_test.dart';
import 'package:submersion/features/trips/domain/entities/liveaboard_details.dart';

void main() {
  group('LiveaboardDetails', () {
    late LiveaboardDetails details;

    setUp(() {
      details = LiveaboardDetails(
        id: 'lb-1',
        tripId: 'trip-1',
        vesselName: 'Ocean Explorer',
        operatorName: 'Red Sea Divers',
        vesselType: 'Motor Yacht',
        cabinType: 'Deluxe Double',
        capacity: 24,
        embarkPort: 'Hurghada Marina',
        embarkLatitude: 27.2579,
        embarkLongitude: 33.8116,
        disembarkPort: 'Hurghada Marina',
        disembarkLatitude: 27.2579,
        disembarkLongitude: 33.8116,
        createdAt: DateTime(2024, 3, 1),
        updatedAt: DateTime(2024, 3, 1),
      );
    });

    test('props returns all fields for equality', () {
      final same = LiveaboardDetails(
        id: 'lb-1',
        tripId: 'trip-1',
        vesselName: 'Ocean Explorer',
        operatorName: 'Red Sea Divers',
        vesselType: 'Motor Yacht',
        cabinType: 'Deluxe Double',
        capacity: 24,
        embarkPort: 'Hurghada Marina',
        embarkLatitude: 27.2579,
        embarkLongitude: 33.8116,
        disembarkPort: 'Hurghada Marina',
        disembarkLatitude: 27.2579,
        disembarkLongitude: 33.8116,
        createdAt: DateTime(2024, 3, 1),
        updatedAt: DateTime(2024, 3, 1),
      );
      expect(details, equals(same));
    });

    test('copyWith preserves values when not provided', () {
      final copy = details.copyWith();
      expect(copy, equals(details));
    });

    test('copyWith updates provided values', () {
      final updated = details.copyWith(vesselName: 'Sea Spirit', capacity: 20);
      expect(updated.vesselName, 'Sea Spirit');
      expect(updated.capacity, 20);
      expect(updated.operatorName, 'Red Sea Divers');
    });

    test('copyWith can set nullable fields to null', () {
      final cleared = details.copyWith(operatorName: null, cabinType: null);
      expect(cleared.operatorName, isNull);
      expect(cleared.cabinType, isNull);
    });

    test('hasEmbarkCoordinates returns true when both lat/lng set', () {
      expect(details.hasEmbarkCoordinates, isTrue);
    });

    test('hasEmbarkCoordinates returns false when missing', () {
      final noCoords = details.copyWith(
        embarkLatitude: null,
        embarkLongitude: null,
      );
      expect(noCoords.hasEmbarkCoordinates, isFalse);
    });

    test('hasDisembarkCoordinates returns true when both lat/lng set', () {
      expect(details.hasDisembarkCoordinates, isTrue);
    });
  });
}
