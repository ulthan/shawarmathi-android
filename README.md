# Shawarmathi POS (Android)

Professional Point of Sale (POS) and Store Management system built with Flutter for Shawarmathi.

## Key Features

- **Real-Time Billing & Sales Counter**: Quick order input for Shawarma (Sarook, Arabi, Bashka, Sahan), Platters, loaded fries, drinks, and fresh juices.
- **Dynamic Products & Rates**: In-app catalog manager to update rates, add new menu items, categorize, or delete items on the fly with local SQLite persistence.
- **Dual Day / Night Theme**: Signature Arabian Shawarmathi design with Saffron Gold & Fiery Charcoal gradients.
- **Digital Receipt Generator**: Multi-item bills with PDF receipt sharing and printing support.
- **Staff PIN Lock / Cashier Mode**: Role-based access control protecting analytics, settings, rate modifications, and deletions with an Owner PIN (Default: 1234).
- **OTA In-App Software Updates (Option B)**:
  - Automated check for updates on startup or manual check from Settings.
  - Queries GitHub Releases for new APK versions.
  - In-app download with live progress bar and direct APK package installer launch.
- **100% Offline Resilience**: All POS operations, menu editing, and sales logging function completely offline using local SQLite.

## Automated Builds & Releases

When pushing tags like `v1.0.0` or running the GitHub Actions workflow manually, `build/app/outputs/flutter-apk/app-release.apk` is automatically compiled and published as a GitHub Release for OTA distribution.
