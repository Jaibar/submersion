<div>
  <img src="assets/icon/icon.png" alt="Submersion Logo" width="80" align="left">
  <h3>Submersion</h3>
  <p><i>A comprehensive, open-source, cross-platform dive logging application.</i></p>
</div>
<br clear="all"/>

[![License: GPL-3.0](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
[![Build macOS](https://img.shields.io/github/actions/workflow/status/submersion-app/submersion/ci.yaml?branch=main&label=macOS&logo=apple)](https://github.com/submersion-app/submersion/actions/workflows/ci.yaml)
[![Build Windows](https://img.shields.io/github/actions/workflow/status/submersion-app/submersion/ci.yaml?branch=main&label=Windows&logo=windows)](https://github.com/submersion-app/submersion/actions/workflows/ci.yaml)
[![Build Linux](https://img.shields.io/github/actions/workflow/status/submersion-app/submersion/ci.yaml?branch=main&label=Linux&logo=linux)](https://github.com/submersion-app/submersion/actions/workflows/ci.yaml)
[![Build Android](https://img.shields.io/github/actions/workflow/status/submersion-app/submersion/ci.yaml?branch=main&label=Android&logo=android)](https://github.com/submersion-app/submersion/actions/workflows/ci.yaml)
[![Build iOS](https://img.shields.io/github/actions/workflow/status/submersion-app/submersion/ci.yaml?branch=main&label=iOS&logo=apple)](https://github.com/submersion-app/submersion/actions/workflows/ci.yaml)

[![Download macOS](https://img.shields.io/badge/Download-macOS-2ea44f?logo=apple)](https://github.com/submersion-app/submersion/releases) [![Download Windows](https://img.shields.io/badge/Download-Windows-2ea44f?logo=windows)](https://github.com/submersion-app/submersion/releases) [![Download Linux](https://img.shields.io/badge/Download-Linux-2ea44f?logo=linux)](https://github.com/submersion-app/submersion/releases) [![Download Android](https://img.shields.io/badge/Download-Android-2ea44f?logo=android)](https://github.com/submersion-app/submersion/releases) [![Download iOS](https://img.shields.io/badge/Download-iOS-2ea44f?logo=apple)](https://github.com/submersion-app/submersion/releases)

Submersion gives scuba divers full ownership of their logbooks. No proprietary formats, no cloud lock-in, no subscription fees. Track analytics, stats, records, and trends across your dives, all stored locally and exportable to open standards. Free and open-source, forever.

## Why Submersion?

Most dive logging software falls into two categories: desktop applications stuck in the past, or mobile apps that lock your data in proprietary clouds. Submersion is different:

- **You Control Your Data** - All data is stored locally in SQLite and can be synced across devices through cloud storage. No account required. No cloud dependency. Export everything, anytime.
- **Truly Cross-Platform** - One app for iOS, Android, macOS, Windows, and Linux. Your logbook works everywhere, and the same details and analytics are available on all platforms.
- **Open Standards** - Full UDDF 3.2 import/export. CSV, FIT, and Excel support. No proprietary formats trapping your dive history.
- **300+ Dive Computers Supported** - Connect via USB or Bluetooth. Powered by [libdivecomputer](https://www.libdivecomputer.org/).
- **Technical Diving Ready** - Buhlmann ZH-L16C decompression, multi-gas support, CNS/OTU tracking, trimix blending, CCR/SCR rebreather modes.
- **Multi-Language** - Available in 10 languages: English, Arabic, German, Spanish, French, Hebrew, Hungarian, Italian, Dutch, and Portuguese.
- **Free Forever** - Open source under GPL-3.0. No premium tiers for core features. No ads.

## Data Philosophy

Submersion is built on these principles:

1. **Local-First** - Your data lives on your device. The app works offline, always.
2. **No Lock-In** - Export your entire logbook to UDDF or CSV at any time. Switch apps without losing history.
3. **No Account Required** - Use the app immediately. No sign-up, no email, no tracking.
4. **Open Source** - Audit the code. Fork it. Improve it. Your dive log software should be transparent.

## Features

### Dive Logging

- Comprehensive dive entry with 40+ data fields per dive
- Automatic dive numbering with gap detection and renumbering
- Entry/exit times with surface interval calculation
- Multi-tank support with gas mixes (air, nitrox, trimix)
- Multi-diver profiles with separate logbooks per diver
- Buddy tracking with roles (buddy, guide, instructor, student)
- Trip organization with liveaboard and itinerary support
- Tags, favorites, and star ratings
- Free-text notes
- Dive types (recreational, technical, training, etc.)

### Dive Sites

- Full site database with GPS coordinates
- Interactive maps with clustering (OpenStreetMap)
- Capture location from device GPS
- Reverse geocoding for country/region
- Depth ranges, difficulty ratings, hazard notes
- Weather integration (OpenWeatherMap API)
- Tide data integration (World Tides API)

### Dive Computer Integration

- **300+ supported dive computers** via libdivecomputer
- Bluetooth Classic, BLE, and USB connectivity
- Manufacturer protocols: Shearwater, Suunto, Mares, Aqualung, and more
- Incremental downloads (new dives only)
- Duplicate detection with fuzzy matching
- Multi-computer support with profile selection

### Profile Analysis

- Interactive depth/temperature/pressure/SAC charts with zoom and pan
- Touch markers showing various metrics at any point
- Ascent rate calculation with color-coded warnings
- Profile event markers (descent, safety stop, gas switch, alerts)
- SAC/RMV overlay for gas consumption
- Deco ceiling curve visualization

### Decompression & Technical Diving

- **Buhlmann ZH-L16C** algorithm with gradient factors
- Real-time NDL, ceiling, and TTS calculations
- 16-compartment tissue loading visualization
- CNS% and OTU oxygen toxicity tracking (NOAA tables)
- ppO2 curve with warning thresholds
- MOD/END/EAD calculations
- CCR and SCR rebreather dive modes with setpoint tracking
- Dive planner with gas planning and deco schedules
- Gas calculators (best mix, blending, consumption)
- Surface interval tool

### Equipment Management

- Track 20+ equipment types with serial numbers, purchase dates, service intervals
- Service reminders with notifications and visual warnings
- Service history and maintenance records
- Equipment sets ("bags") for quick selection
- Per-dive gear tracking
- Tank presets (AL80, HP100, etc.)

### Certifications & Training

- Store all certifications with card numbers and dates
- 12+ agency support: PADI, SSI, NAUI, SDI/TDI, GUE, RAID, and more
- Expiry tracking with warnings
- Course tracking with linked training dives
- Instructor and dive center records

### Marine Life

- Log species sightings per dive
- Species reference database
- Track marine life encounters over time

### Media

- Attach photos to dives from camera or gallery
- GPS-tagged photo import with auto-matching
- Photo viewer with full-screen support
- Video attachment support

### Statistics & Records

- Total dives, bottom time, depth statistics
- Breakdown by year, country, site, dive type
- Personal records: deepest, longest, coldest, warmest
- Depth distribution histograms

### Import & Export

- **UDDF 3.2** - Universal Dive Data Format, the open standard
- **CSV** - Spreadsheet-compatible with configurable columns
- **FIT** - Garmin dive watch file import
- **Excel** - Spreadsheet import
- **PDF** - Printable logbook pages
- Full database backup and restore

### Cloud Sync

- **Google Drive** integration for cross-device sync
- **iCloud** integration for Apple ecosystem sync
- Conflict detection and resolution
- Fully optional -- the app works entirely offline

### Wearable Integration

- **Apple Watch** dive import via HealthKit
- Fuzzy matching to pair wearable data with logged dives
- Heart rate data overlay on dive profiles

### Auto-Update (Desktop)

- Automatic update checking for macOS, Windows, and Linux
- In-app update notifications with changelog

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.38 or higher
- Git with submodule support (libdivecomputer is a submodule)

### Quick Start

```bash
# Clone the repository with submodules
git clone --recurse-submodules https://github.com/submersion-app/submersion.git
cd submersion

# First-time setup (installs deps, configures git hooks, runs codegen)
./scripts/setup.sh

# Or manually:
flutter pub get
git config core.hooksPath hooks
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run -d macos    # or: windows, linux, ios, android
```

### Build for Release

```bash
# iOS
flutter build ios

# Android
flutter build apk

# macOS
flutter build macos

# Windows
flutter build windows

# Linux
flutter build linux
```

### macOS: Building Without a Developer Certificate

If you don't have an Apple Developer certificate, you can still build and run the app locally using ad-hoc signing. This creates a non-sandboxed build that works on any Mac.

```bash
# Run the no-sandbox build script
./scripts/release/build_nosandbox_macos.sh
```

This script:

1. Builds the macOS app with Flutter
2. Re-signs it with an ad-hoc signature (no Apple certificate required)
3. Applies no-sandbox entitlements for full file system access

The built app will be at `build/macos/Build/Products/Release/submersion.app`.

**Running the app:** macOS Gatekeeper will block unsigned apps by default. To run:

1. Right-click (or Control-click) on `submersion.app`
2. Select "Open" from the context menu
3. Click "Open" in the dialog that appears

You only need to do this once - subsequent launches will work normally.

> **Note:** This build cannot be distributed via the Mac App Store (which requires sandboxing). It's intended for local testing and direct distribution.

### Windows: Building from Source

Windows builds require no code signing for local use. You need [Visual Studio](https://visualstudio.microsoft.com/) with the **Desktop development with C++** workload installed (the free Community edition works).

```bash
# Build the app
flutter build windows --release
```

The built app will be at `build\windows\x64\runner\Release\`.

> **Note:** Windows SmartScreen may show an "unrecognized app" warning for unsigned executables. Click "More info" then "Run anyway" to proceed.

### Linux: Building from Source

Linux builds require GTK3 and several native development libraries. Install them first:

**Debian/Ubuntu:**

```bash
sudo apt-get update
sudo apt-get install -y \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev libstdc++-12-dev \
  libsqlite3-dev libsecret-1-dev
```

**Fedora:**

```bash
sudo dnf install -y \
  clang cmake ninja-build pkg-config \
  gtk3-devel xz-devel libstdc++-devel \
  sqlite-devel libsecret-devel
```

**Arch Linux:**

```bash
sudo pacman -S --needed \
  clang cmake ninja pkg-config \
  gtk3 xz sqlite libsecret
```

Then build:

```bash
flutter build linux --release
```

The built app will be at `build/linux/x64/release/bundle/`.

## Common Commands

```bash
# Run on macOS
flutter run -d macos

# Run tests
flutter test

# Run tests with coverage
flutter test --coverage

# Analyze code
flutter analyze

# Format code
dart format lib/ test/

# Watch mode for code generation
dart run build_runner watch

# Clean rebuild
flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs
```

## Git Hooks

Pre-push hooks are configured in the `hooks/` directory. They automatically run:

- `dart format --set-exit-if-changed` - ensures code is formatted
- `flutter analyze` - catches lint issues
- `flutter test` - runs unit tests

**Setup:** Run `git config core.hooksPath hooks` (or use `./scripts/setup.sh`)

**Bypass (if needed):** `git push --no-verify`

## Architecture

Submersion follows clean architecture principles with clear separation of concerns:

```text
lib/
├── core/                   # Shared infrastructure
│   ├── accessibility/      # Accessibility utilities
│   ├── constants/          # App-wide constants
│   ├── data/               # Base data layer
│   ├── database/           # Drift ORM schema, migrations, tables
│   ├── deco/               # Decompression algorithms (Buhlmann ZH-L16C)
│   ├── domain/             # Base domain layer
│   ├── errors/             # Error handling
│   ├── models/             # Shared models
│   ├── performance/        # Performance utilities
│   ├── providers/          # Global Riverpod providers
│   ├── router/             # Navigation (go_router)
│   ├── services/           # Location, weather, database services
│   ├── theme/              # Material 3 theming
│   ├── tide/               # Tide data processing
│   └── utils/              # Shared utilities
├── features/               # Feature modules
│   ├── auto_update/        # Desktop auto-update
│   ├── backup/             # Database backup/restore
│   ├── buddies/            # Buddy contact management
│   ├── certifications/     # Certification tracking
│   ├── courses/            # Training course tracking
│   ├── dashboard/          # Home dashboard
│   ├── deco_calculator/    # Decompression calculator
│   ├── dive_centers/       # Dive center/operator database
│   ├── dive_computer/      # Dive computer connectivity
│   ├── dive_import/        # Dive import processing
│   ├── dive_log/           # Core dive logging
│   ├── dive_planner/       # Dive planning tools
│   ├── dive_sites/         # Site management
│   ├── dive_types/         # Dive type definitions
│   ├── divers/             # Multi-diver profiles
│   ├── equipment/          # Gear tracking & service
│   ├── gas_calculators/    # Gas mix calculators
│   ├── import_export/      # UDDF, CSV, FIT, Excel, PDF
│   ├── maps/               # Interactive maps
│   ├── marine_life/        # Species sightings
│   ├── media/              # Photo & video management
│   ├── notifications/      # Service reminders
│   ├── onboarding/         # First-run setup
│   ├── planning/           # Dive planning
│   ├── settings/           # App settings & cloud sync
│   ├── signatures/         # Digital signatures
│   ├── statistics/         # Analytics & records
│   ├── surface_interval_tool/ # Surface interval calculator
│   ├── tags/               # Dive tagging
│   ├── tank_presets/       # Tank preset management
│   ├── tides/              # Tide data display
│   ├── tools/              # Utility tools
│   ├── transfer/           # Data transfer
│   ├── trips/              # Trip & liveaboard management
│   └── universal_import/   # Universal file import
├── l10n/                   # Localization (10 languages)
├── shared/                 # Reusable widgets
└── packages/
    └── libdivecomputer_plugin/ # FFI bindings for libdivecomputer
```

**Tech Stack:**

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Framework** | Flutter 3.x | Cross-platform UI (iOS, Android, macOS, Windows, Linux) |
| **Language** | Dart 3.10+ | Application code |
| **State Management** | Riverpod | Reactive state with providers and notifiers |
| **Database** | Drift | Type-safe SQLite ORM with migrations |
| **Navigation** | go_router | Declarative routing with ShellRoute |
| **Charts** | fl_chart | Interactive dive profiles and statistics |
| **Maps** | flutter_map | OpenStreetMap with marker clustering |
| **Dive Computers** | libdivecomputer (FFI) | 300+ device support via native bindings |
| **Cloud Sync** | googleapis, google_sign_in | Google Drive and iCloud sync |
| **Health Data** | health | Apple Watch/HealthKit integration |
| **PDF** | pdf, printing | Logbook PDF generation |
| **Localization** | Flutter l10n (ARB) | 10-language support |
| **Auto-Update** | auto_updater | Desktop update mechanism |
| **Notifications** | flutter_local_notifications | Service reminders |

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed documentation.

## Database

The database uses Drift ORM with 20+ tables. Key tables include:

| Table | Description |
|-------|-------------|
| `divers` | Diver profiles with emergency contacts and medical info |
| `dives` | Core dive logs with 40+ fields (depth, duration, conditions, deco, etc.) |
| `dive_profiles` | Time-series depth/temp/pressure data points per dive |
| `dive_tanks` | Tank info (volume, gas mix, pressures) per dive |
| `dive_sites` | Dive site locations with GPS, descriptions, conditions |
| `gear` | Equipment items with service tracking |
| `gear_service_records` | Service history per gear item |
| `trips` | Dive trip organization with liveaboard support |
| `dive_computers` | Saved dive computer configurations |
| `certifications` | Diver certifications with expiry tracking |
| `courses` | Training courses with linked dives |
| `buddies` | Buddy contacts with certification info |
| `dive_centers` | Dive center/operator database |
| `marine_life_sightings` | Species spotted on dives |
| `species` | Marine life species reference data |

## Localization

Submersion supports 10 languages via Flutter's built-in localization framework using ARB files:

| Language | Code |
|----------|------|
| English | `en` |
| Arabic | `ar` |
| German | `de` |
| Spanish | `es` |
| French | `fr` |
| Hebrew | `he` |
| Hungarian | `hu` |
| Italian | `it` |
| Dutch | `nl` |
| Portuguese | `pt` |

Translation files are located in `lib/l10n/arb/`. Contributions for additional languages are welcome.

## Roadmap

| Version | Status | Highlights |
|---------|--------|------------|
| **v1.0** | Complete | Core logging, sites, gear, statistics, UDDF/CSV/PDF |
| **v1.1** | Complete | GPS integration, maps, tags, profile zoom/pan |
| **v1.5** | Complete | Dive computer connectivity, deco algorithms, O2 tracking, CCR/SCR, dive planner |
| **v2.0** | In Progress | Cloud sync, photos, multi-language, wearable integration, auto-update |

See [docs/FEATURE_ROADMAP.md](docs/FEATURE_ROADMAP.md) for the complete development plan.

## Contributing

Contributions are welcome! Submersion is built by divers, for divers.

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes with tests
4. Run `dart format .` to format code
5. Submit a pull request

Please run `flutter analyze` and `flutter test` before submitting.

## License

Submersion is free software, released under the **GNU General Public License v3.0**.

You are free to use, modify, and distribute this software. If you distribute modified versions, you must also release the source code under GPL-3.0.

See [LICENSE](LICENSE) for the full text.

## Acknowledgments

Submersion builds on the work of the dive logging community:

- **[libdivecomputer](https://www.libdivecomputer.org/)** -- The open-source library powering dive computer communication
- **[Subsurface](https://subsurface-divelog.org/)** -- Inspiration and the UDDF format
- **[Flutter](https://flutter.dev/)** -- Cross-platform framework making this possible

---

*Dive safe. Log everything. Own your data.*
