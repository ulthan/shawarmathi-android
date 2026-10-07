# Shawarmathi POS

[![Platform](https://img.shields.io/badge/Platform-Android-green.svg)](https://flutter.dev)
[![Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B.svg?logo=flutter)](https://flutter.dev)
[![Database](https://img.shields.io/badge/Storage-SQLite%20(Offline%20First)-blue.svg)](https://pub.dev/packages/sqflite)
[![Release](https://img.shields.io/badge/Release-v1.0.0-orange.svg)](https://github.com/ulthan/shawarmathi-android/releases)

A modern, standalone Point of Sale (POS) and inventory counter application engineered specifically for restaurant operations. Built with Flutter, Shawarmathi POS delivers high-speed order processing, resilient offline-first data persistence, role-based access management, and over-the-air updates.

---

## 🌟 Key Features

### ⚡ Rapid Order & Checkout Terminal
- Optimized counter interface designed for high-turnover service.
- Pre-configured product catalog including Shawarma specialties (Sarook, Arabi, Bashka, Sahan), platters, sides, and beverages.
- Instant item selection, quantities, add-ons, and real-time total computation.

### 📦 Dynamic Catalog & Pricing Management
- Live product and pricing configuration directly from the administrative panel.
- On-the-fly category management and item status toggling.
- Zero server dependency — all changes persist instantly via an embedded SQLite engine.

### 🔐 Role-Based Access Control (RBAC)
- **Cashier Mode**: Clean checkout experience restricted to bill creation and printing.
- **Manager/Owner PIN Protection**: Critical actions (discounting, menu pricing changes, order cancellations, and end-of-day analytics) are guarded behind secure authentication.

### 🧾 Digital Invoicing & Receipt Export
- Instant receipt rendering with multi-item breakdowns, taxes, and payment mode stamps.
- High-fidelity PDF generation with direct sharing and thermal printer compatibility.

### 🔄 Over-The-Air (OTA) Updates
- Native in-app version checker integrated with GitHub Releases.
- Automated background download with real-time progress indicators and streamlined APK package installer execution.

### 🛡️ 100% Offline-First Architecture
- Engineered to remain completely functional during network outages.
- Local sales recording, reporting, and transaction logs stored securely on-device.

---

## 🏗️ Technical Architecture

| Component | Specification |
| :--- | :--- |
| **Framework** | Flutter (Dart SDK ^3.13) |
| **State Management** | Provider |
| **Local Database** | SQLite via `sqflite` |
| **Document Engine** | PDF & Printing API (`pdf`, `open_filex`) |
| **Distribution / OTA** | GitHub REST API + In-App Package Installer |
| **Target OS** | Android 7.0+ (API Level 24+) |

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.13 or later)
- Android SDK & Build Tools
- Java 17

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ulthan/shawarmathi-android.git
   cd shawarmathi-android
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on a connected Android device:**
   ```bash
   flutter run
   ```

4. **Build a production APK:**
   ```bash
   flutter build apk --release
   ```

---

## 📦 Release & Distribution

Releases are automatically built via GitHub Actions upon tagging:
```bash
git tag v1.0.1
git push origin v1.0.1
```
The compiled APK is published directly to [GitHub Releases](https://github.com/ulthan/shawarmathi-android/releases).

