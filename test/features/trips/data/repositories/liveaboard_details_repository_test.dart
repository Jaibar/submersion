import 'package:flutter_test/flutter_test.dart';
import 'package:submersion/features/trips/data/repositories/liveaboard_details_repository.dart';
import 'package:submersion/features/trips/data/repositories/trip_repository.dart';
import 'package:submersion/features/trips/domain/entities/liveaboard_details.dart';
import 'package:submersion/features/trips/domain/entities/trip.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late LiveaboardDetailsRepository repository;
  late TripRepository tripRepository;
  late String testTripId;

  Trip createTestTrip({String id = '', String name = 'Test Trip'}) {
    final now = DateTime.now();
    return Trip(
      id: id,
      name: name,
      startDate: now,
      endDate: now.add(const Duration(days: 7)),
      createdAt: now,
      updatedAt: now,
    );
  }

  LiveaboardDetails createTestDetails({
    String id = '',
    String? tripId,
    String vesselName = 'MV Test Vessel',
    String? operatorName = 'Test Operator',
    String? vesselType = 'Motor Yacht',
    String? cabinType = 'Standard',
    int? capacity = 20,
    String? embarkPort = 'Male',
    double? embarkLatitude = 4.1755,
    double? embarkLongitude = 73.5093,
    String? disembarkPort = 'Male',
    double? disembarkLatitude = 4.1755,
    double? disembarkLongitude = 73.5093,
  }) {
    final now = DateTime.now();
    return LiveaboardDetails(
      id: id,
      tripId: tripId ?? testTripId,
      vesselName: vesselName,
      operatorName: operatorName,
      vesselType: vesselType,
      cabinType: cabinType,
      capacity: capacity,
      embarkPort: embarkPort,
      embarkLatitude: embarkLatitude,
      embarkLongitude: embarkLongitude,
      disembarkPort: disembarkPort,
      disembarkLatitude: disembarkLatitude,
      disembarkLongitude: disembarkLongitude,
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() async {
    await setUpTestDatabase();
    repository = LiveaboardDetailsRepository();
    tripRepository = TripRepository();

    // Create a trip to satisfy FK constraint
    final trip = await tripRepository.createTrip(
      createTestTrip(name: 'Liveaboard Trip'),
    );
    testTripId = trip.id;
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  group('LiveaboardDetailsRepository', () {
    group('getByTripId', () {
      test('should return null when no details exist', () async {
        final result = await repository.getByTripId(testTripId);

        expect(result, isNull);
      });

      test('should return null for non-existent trip id', () async {
        final result = await repository.getByTripId('non-existent-id');

        expect(result, isNull);
      });
    });

    group('createOrUpdate', () {
      test(
        'should create new details with generated ID when ID is empty',
        () async {
          final details = createTestDetails();

          final created = await repository.createOrUpdate(details);

          expect(created.id, isNotEmpty);
          expect(created.tripId, equals(testTripId));
          expect(created.vesselName, equals('MV Test Vessel'));
        },
      );

      test('should create details with all fields', () async {
        final details = createTestDetails(
          vesselName: 'MY Ocean Explorer',
          operatorName: 'Explorer Diving',
          vesselType: 'Sailing Yacht',
          cabinType: 'Deluxe',
          capacity: 16,
          embarkPort: 'Hurghada',
          embarkLatitude: 27.2579,
          embarkLongitude: 33.8116,
          disembarkPort: 'Port Ghalib',
          disembarkLatitude: 25.5500,
          disembarkLongitude: 34.6333,
        );

        await repository.createOrUpdate(details);
        final fetched = await repository.getByTripId(testTripId);

        expect(fetched, isNotNull);
        expect(fetched!.vesselName, equals('MY Ocean Explorer'));
        expect(fetched.operatorName, equals('Explorer Diving'));
        expect(fetched.vesselType, equals('Sailing Yacht'));
        expect(fetched.cabinType, equals('Deluxe'));
        expect(fetched.capacity, equals(16));
        expect(fetched.embarkPort, equals('Hurghada'));
        expect(fetched.embarkLatitude, closeTo(27.2579, 0.001));
        expect(fetched.embarkLongitude, closeTo(33.8116, 0.001));
        expect(fetched.disembarkPort, equals('Port Ghalib'));
        expect(fetched.disembarkLatitude, closeTo(25.5500, 0.001));
        expect(fetched.disembarkLongitude, closeTo(34.6333, 0.001));
      });

      test('should create details with nullable fields as null', () async {
        final now = DateTime.now();
        final details = LiveaboardDetails(
          id: '',
          tripId: testTripId,
          vesselName: 'Simple Vessel',
          createdAt: now,
          updatedAt: now,
        );

        await repository.createOrUpdate(details);
        final fetched = await repository.getByTripId(testTripId);

        expect(fetched, isNotNull);
        expect(fetched!.vesselName, equals('Simple Vessel'));
        expect(fetched.operatorName, isNull);
        expect(fetched.vesselType, isNull);
        expect(fetched.cabinType, isNull);
        expect(fetched.capacity, isNull);
        expect(fetched.embarkPort, isNull);
        expect(fetched.embarkLatitude, isNull);
        expect(fetched.embarkLongitude, isNull);
        expect(fetched.disembarkPort, isNull);
        expect(fetched.disembarkLatitude, isNull);
        expect(fetched.disembarkLongitude, isNull);
      });

      test('should update existing details when called again', () async {
        final details = createTestDetails(vesselName: 'Original Vessel');
        final created = await repository.createOrUpdate(details);

        final updated = created.copyWith(vesselName: 'Updated Vessel');
        await repository.createOrUpdate(updated);

        final fetched = await repository.getByTripId(testTripId);

        expect(fetched, isNotNull);
        expect(
          fetched!.id,
          equals(created.id),
        ); // Verify same record was updated
        expect(fetched.vesselName, equals('Updated Vessel'));
      });

      test(
        'should update existing details when called with empty id for same tripId',
        () async {
          final details = createTestDetails(vesselName: 'First Vessel');
          final created = await repository.createOrUpdate(details);

          // Call again with empty id but same tripId
          final secondDetails = createTestDetails(vesselName: 'Second Vessel');
          await repository.createOrUpdate(secondDetails);

          final fetched = await repository.getByTripId(testTripId);
          expect(fetched, isNotNull);
          expect(
            fetched!.id,
            equals(created.id),
          ); // Same record, not a duplicate
          expect(fetched.vesselName, equals('Second Vessel'));
        },
      );

      test('should update a specific field while preserving others', () async {
        final details = createTestDetails(
          vesselName: 'MV Coral',
          operatorName: 'Coral Diving',
          capacity: 12,
        );
        final created = await repository.createOrUpdate(details);

        final updated = created.copyWith(operatorName: 'New Operator');
        await repository.createOrUpdate(updated);

        final fetched = await repository.getByTripId(testTripId);

        expect(fetched, isNotNull);
        expect(fetched!.vesselName, equals('MV Coral'));
        expect(fetched.operatorName, equals('New Operator'));
        expect(fetched.capacity, equals(12));
      });
    });

    group('getByTripId after create', () {
      test('should return created details with matching fields', () async {
        final details = createTestDetails(vesselName: 'MV Retriever');

        final created = await repository.createOrUpdate(details);
        final fetched = await repository.getByTripId(testTripId);

        expect(fetched, isNotNull);
        expect(fetched!.id, equals(created.id));
        expect(fetched.tripId, equals(testTripId));
        expect(fetched.vesselName, equals('MV Retriever'));
        expect(fetched.operatorName, equals('Test Operator'));
        expect(fetched.vesselType, equals('Motor Yacht'));
        expect(fetched.cabinType, equals('Standard'));
        expect(fetched.capacity, equals(20));
        expect(fetched.embarkPort, equals('Male'));
        expect(fetched.disembarkPort, equals('Male'));
      });
    });

    group('deleteByTripId', () {
      test('should remove existing details', () async {
        await repository.createOrUpdate(createTestDetails());

        // Verify details exist
        final beforeDelete = await repository.getByTripId(testTripId);
        expect(beforeDelete, isNotNull);

        await repository.deleteByTripId(testTripId);

        final afterDelete = await repository.getByTripId(testTripId);
        expect(afterDelete, isNull);
      });

      test('should be a no-op when no details exist (no error)', () async {
        // Should complete without throwing
        await expectLater(repository.deleteByTripId(testTripId), completes);
      });

      test('should be a no-op for non-existent trip id', () async {
        await expectLater(
          repository.deleteByTripId('non-existent-trip'),
          completes,
        );
      });
    });
  });
}
