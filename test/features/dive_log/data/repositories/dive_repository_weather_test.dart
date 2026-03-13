import 'package:flutter_test/flutter_test.dart';
import 'package:submersion/core/constants/enums.dart';
import 'package:submersion/features/dive_log/data/repositories/dive_repository_impl.dart';
import 'package:submersion/features/dive_log/domain/entities/dive.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late DiveRepository repository;

  setUp(() async {
    await setUpTestDatabase();
    repository = DiveRepository();
  });

  tearDown(() async {
    await tearDownTestDatabase();
  });

  group('DiveRepository weather fields', () {
    test(
      'createDive persists weather fields and getDiveById retrieves them',
      () async {
        final dive = Dive(
          id: 'weather-test-1',
          dateTime: DateTime(2024, 6, 15),
          windSpeed: 5.5,
          windDirection: CurrentDirection.northEast,
          cloudCover: CloudCover.partlyCloudy,
          precipitation: Precipitation.none,
          humidity: 75.0,
          weatherDescription: 'Warm and sunny',
          weatherSource: WeatherSource.openMeteo,
          weatherFetchedAt: DateTime(2024, 6, 15, 10, 0),
        );

        await repository.createDive(dive);
        final retrieved = await repository.getDiveById('weather-test-1');

        expect(retrieved, isNotNull);
        expect(retrieved!.windSpeed, 5.5);
        expect(retrieved.windDirection, CurrentDirection.northEast);
        expect(retrieved.cloudCover, CloudCover.partlyCloudy);
        expect(retrieved.precipitation, Precipitation.none);
        expect(retrieved.humidity, 75.0);
        expect(retrieved.weatherDescription, 'Warm and sunny');
        expect(retrieved.weatherSource, WeatherSource.openMeteo);
        expect(retrieved.weatherFetchedAt, isNotNull);
      },
    );

    test('null weather fields persist as null', () async {
      final dive = Dive(id: 'weather-test-2', dateTime: DateTime(2024, 6, 15));

      await repository.createDive(dive);
      final retrieved = await repository.getDiveById('weather-test-2');

      expect(retrieved, isNotNull);
      expect(retrieved!.windSpeed, isNull);
      expect(retrieved.windDirection, isNull);
      expect(retrieved.cloudCover, isNull);
      expect(retrieved.precipitation, isNull);
      expect(retrieved.humidity, isNull);
      expect(retrieved.weatherDescription, isNull);
      expect(retrieved.weatherSource, isNull);
      expect(retrieved.weatherFetchedAt, isNull);
    });

    test('updateDive updates weather fields', () async {
      final dive = Dive(id: 'weather-test-3', dateTime: DateTime(2024, 6, 15));
      await repository.createDive(dive);

      final updated = dive.copyWith(
        windSpeed: 8.0,
        cloudCover: CloudCover.overcast,
        weatherSource: WeatherSource.manual,
      );
      await repository.updateDive(updated);

      final retrieved = await repository.getDiveById('weather-test-3');
      expect(retrieved!.windSpeed, 8.0);
      expect(retrieved.cloudCover, CloudCover.overcast);
      expect(retrieved.weatherSource, WeatherSource.manual);
    });
  });
}
