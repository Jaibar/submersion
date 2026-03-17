# Dive Time Timezone Fix

## Problem

Dive times imported from dive computers are shifted by a number of hours equal to the user's UTC offset. User reports confirm this across multiple devices:

- Shearwater Perdix 2: shifted behind by 8 hours (PST user)
- Shearwater Tern: shifted forward by 13 hours (GMT+13 user)
- Shearwater Perdix: 7-hour shift matching PDT offset
- DeepSix Excursion: 4-hour shift matching EDT offset

The root cause is a bug chain in the import pipeline where local wall-clock time components are interpreted as UTC, then converted back to local for display, producing a double-shift.

## Design Principle

Dive times represent wall-clock time at the dive site. They must never be shifted, converted, or interpreted through any timezone. Whatever time the diver saw on their dive computer is what the app displays, permanently, regardless of the device's current timezone.

## Storage Convention: Wall-Clock-as-UTC

All dive times are stored as `DateTime.utc(y, m, d, h, min, s).millisecondsSinceEpoch`. The UTC label is a storage mechanism, not a semantic claim about timezone. This means the UTC components of the stored epoch equal the wall-clock time the diver experienced.

Display code formats these UTC DateTimes directly. `DateFormat.format(utcDateTime)` uses the UTC components, so the displayed time is always the wall-clock time regardless of device timezone.

## Bug Chain (Current Behavior)

1. libdivecomputer provides date/time components (year, month, day, hour, minute, second) plus a `timezone` field (seconds east of UTC, or `DC_TIMEZONE_NONE` if unknown). For most dive computers, these components are local wall-clock time.
2. Native code (Swift/Kotlin) forces a UTC calendar to interpret these components, treating "7:42 AM local" as "7:42 AM UTC" and producing the wrong POSIX epoch.
3. Dart mapper creates `DateTime.fromMillisecondsSinceEpoch(epoch * 1000)` (a local DateTime from the wrong epoch).
4. UI calls `.toLocal()` or `DateFormat.format()` on this local DateTime.
5. Result: every dive time is shifted by the user's UTC offset.

## Changes

### 1. Pigeon API

Replace the single `dateTimeEpoch` field in `ParsedDive` with raw components:

```dart
// In pigeons/dive_computer_api.dart - ParsedDive class
// Remove: final int dateTimeEpoch;
// Add:
final int dateTimeYear;
final int dateTimeMonth;
final int dateTimeDay;
final int dateTimeHour;
final int dateTimeMinute;
final int dateTimeSecond;
final int? dateTimeTimezoneOffset; // seconds east of UTC, null if unknown
```

After modifying the Pigeon definition, regenerate with:
```bash
dart run pigeon --input pigeons/dive_computer_api.dart
```

### 2. Native Code (Swift and Kotlin)

**Files:**
- `packages/libdivecomputer_plugin/ios/Classes/DiveComputerHostApiImpl.swift` (lines 408-420)
- `packages/libdivecomputer_plugin/macos/Classes/DiveComputerHostApiImpl.swift` (lines 408-420)
- `packages/libdivecomputer_plugin/android/src/main/kotlin/com/submersion/libdivecomputer/DiveComputerHostApiImpl.kt` (lines 281-295)

Remove the UTC calendar epoch calculation. Pass through the raw components from the C struct (`dive.year`, `dive.month`, `dive.day`, `dive.hour`, `dive.minute`, `dive.second`) and the timezone field (`dive.timezone`). Map `DC_TIMEZONE_NONE` (which equals `INT_MIN` per `libdivecomputer/datetime.h`) to `nil`/`null` on the Pigeon side.

The C wrapper already copies `dt.timezone` into `dive->timezone` (`libdc_download.c:271`), so the value is available in the struct.

### 3. Dart Mapper

**File:** `lib/features/dive_computer/data/services/parsed_dive_mapper.dart`

```dart
DateTime startTime;
if (parsed.dateTimeTimezoneOffset != null) {
  // Timezone provided: components are UTC. Convert to local wall-clock
  // by applying the offset, then re-wrap as UTC for storage.
  final utc = DateTime.utc(
    parsed.dateTimeYear, parsed.dateTimeMonth, parsed.dateTimeDay,
    parsed.dateTimeHour, parsed.dateTimeMinute, parsed.dateTimeSecond,
  );
  final local = utc.add(Duration(seconds: parsed.dateTimeTimezoneOffset!));
  startTime = DateTime.utc(
    local.year, local.month, local.day,
    local.hour, local.minute, local.second,
  );
} else {
  // No timezone: components are already local wall-clock time.
  startTime = DateTime.utc(
    parsed.dateTimeYear, parsed.dateTimeMonth, parsed.dateTimeDay,
    parsed.dateTimeHour, parsed.dateTimeMinute, parsed.dateTimeSecond,
  );
}
```

Devices affected by the timezone branch: Shearwater Teric (logversion >= 9), DiveSystem iDive, Halcyon Symbios, Divesoft Freedom, SEAC Screen, and some Uwatec/Scubapro models.

Devices using the no-timezone branch: Shearwater Perdix/Tern/Peregrine (non-Teric), Suunto, Mares, Oceanic, Cressi, Heinrichs Weikamp, and most others.

### 4. Manual Entry

**File:** `lib/features/dive_log/presentation/pages/dive_edit_page.dart` (lines 3283-3301)

Change `DateTime(...)` to `DateTime.utc(...)` for both entry and exit DateTimes:

```dart
final entryDateTime = DateTime.utc(
  _entryDate.year, _entryDate.month, _entryDate.day,
  _entryTime.hour, _entryTime.minute,
);
```

Same change for `exitDateTime` construction.

### 5. Database Read Path

**File:** `lib/features/dive_log/data/repositories/dive_repository_impl.dart`

Every place a dive DateTime is reconstructed from the database must use `isUtc: true`:

```dart
// Before:
dateTime: DateTime.fromMillisecondsSinceEpoch(row.diveDateTime),

// After:
dateTime: DateTime.fromMillisecondsSinceEpoch(row.diveDateTime, isUtc: true),
```

This applies to `_mapRowToDive`, `_mapRowToDiveWithPreloadedData`, and any other mapping methods. Same for `entryTime` and `exitTime` fields.

### 6. Display Path

No changes needed to formatting code. `UnitFormatter.formatDate/formatTime/formatDateTime` in `lib/core/utils/unit_formatter.dart` call `DateFormat.format(dateTime)`, which uses the DateTime's own components. For UTC DateTimes, this formats the UTC components directly.

The `.toLocal()` calls in `dive_detail_page.dart` (lines 2771-2902) are for tide prediction times, not dive times. Tides are genuinely UTC and must continue using `.toLocal()`. Do not change those.

### 7. Profile and Tank Timestamps

Profile points (`dive_profiles` table) and tank pressure points store timestamps as seconds-from-dive-start (relative offsets), not absolute DateTimes. These are not affected by this change.

## Schema Migration

### New Column

Add `importVersion` (nullable integer) to the `dives` table:

```dart
IntColumn get importVersion => integer().nullable()();
```

- `null` = pre-fix dive (legacy)
- `1` = post-fix dive (wall-clock-as-UTC convention)

All new dives (imported or manual) are created with `importVersion: Value(1)`.

### Automatic Migration

Run once on app upgrade as a Drift schema migration step.

**Imported dives** (identified by `diveComputerModel IS NOT NULL` OR `computerId IS NOT NULL`):
- Already accidentally stored in wall-clock-as-UTC format (the import bug treated local components as UTC, which happens to be the target format).
- Action: Set `importVersion = 1`. No timestamp change.

**Wearable-imported dives** (identified by `wearableSource IS NOT NULL`):
- Likely stored as true local epoch (HealthKit provides proper local DateTimes).
- Action: Shift timestamps by the device's current UTC offset: `newEpoch = oldEpoch - localOffsetMs`. Set `importVersion = 1`.

**Manual dives** (all remaining: `diveComputerModel IS NULL` AND `computerId IS NULL` AND `wearableSource IS NULL`):
- Stored as true local epoch.
- Action: Shift timestamps by the device's current UTC offset: `newEpoch = oldEpoch - localOffsetMs`. Set `importVersion = 1`.

The auto-migration uses the device's current UTC offset, which is imperfect if the user changed timezones since entering a dive. The bulk-fix tool handles edge cases.

The migration must shift `diveDateTime`, `entryTime`, and `exitTime` columns for affected rows.

## Bulk-Fix Tool

A screen accessible from Settings that lets users manually correct dive times.

### User Flow

1. User navigates to Settings > Fix Dive Times
2. User selects dives to fix (filter by date range, select individual dives, or select all)
3. User enters an hour offset to apply (e.g., +7, -5)
4. Preview shows before/after times for selected dives
5. User confirms
6. Tool applies the offset to `diveDateTime`, `entryTime`, and `exitTime` for selected dives

### Scope

This tool is for correcting any dives whose times are wrong after the automatic migration. It applies a uniform hour offset to all selected dives.

## Testing Strategy

### Unit Tests

- Dart mapper: verify wall-clock-as-UTC construction with and without timezone offset
- Migration logic: verify imported dives are left unchanged, manual dives are shifted correctly
- Bulk-fix: verify offset application and preview calculation

### Integration Tests

- Full import pipeline: mock Pigeon ParsedDive with raw components, verify stored epoch has correct wall-clock-as-UTC value
- Manual entry: verify DateTime.utc construction and correct storage
- Database round-trip: verify that stored and retrieved times display identically

### Edge Cases

- Timezone offset that crosses a date boundary (e.g., UTC+13 at 11 PM local)
- Negative timezone offsets
- `dateTimeTimezoneOffset` of zero (UTC, not unknown)
- Devices that provide `DC_TIMEZONE_NONE`
- Leap seconds (should be a no-op since we pass through components)

## Files Changed

| File | Change |
|------|--------|
| `packages/libdivecomputer_plugin/pigeons/dive_computer_api.dart` | Replace `dateTimeEpoch` with component fields + timezone |
| `packages/libdivecomputer_plugin/ios/Classes/DiveComputerHostApiImpl.swift` | Pass through raw components instead of UTC epoch |
| `packages/libdivecomputer_plugin/macos/Classes/DiveComputerHostApiImpl.swift` | Same as iOS |
| `packages/libdivecomputer_plugin/android/src/main/kotlin/com/submersion/libdivecomputer/DiveComputerHostApiImpl.kt` | Same as iOS |
| `packages/libdivecomputer_plugin/lib/src/generated/dive_computer_api.g.dart` | Regenerated by Pigeon |
| `lib/features/dive_computer/data/services/parsed_dive_mapper.dart` | Wall-clock-as-UTC DateTime construction |
| `lib/features/dive_log/presentation/pages/dive_edit_page.dart` | `DateTime(...)` to `DateTime.utc(...)` |
| `lib/features/dive_log/data/repositories/dive_repository_impl.dart` | Add `isUtc: true` to all DateTime reconstructions |
| `lib/core/database/database.dart` | Add `importVersion` column, migration step |
| New: `lib/features/settings/presentation/pages/fix_dive_times_page.dart` | Bulk-fix tool UI |
| New: `lib/features/settings/data/services/dive_time_migration_service.dart` | Migration and bulk-fix logic |
