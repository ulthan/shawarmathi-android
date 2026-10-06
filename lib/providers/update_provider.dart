import 'dart:async';
import 'package:flutter/foundation.dart';

import '../models/app_update_info.dart';
import '../services/app_update_service.dart';

enum UpdateStatus {
  idle,
  checking,
  available,
  upToDate,
  downloading,
  downloaded,
  error,
}

class UpdateProvider extends ChangeNotifier {
  final AppUpdateService _updateService;

  UpdateStatus _status = UpdateStatus.idle;
  AppUpdateInfo? _updateInfo;
  double _progress = 0.0;
  int _receivedBytes = 0;
  int _totalBytes = 0;
  String? _downloadedApkPath;
  String? _errorMessage;
  bool _autoCheckOnStartup = true;
  DateTime? _lastChecked;

  UpdateProvider({AppUpdateService? updateService})
      : _updateService = updateService ?? GitHubAppUpdateService();

  UpdateStatus get status => _status;
  AppUpdateInfo? get updateInfo => _updateInfo;
  double get progress => _progress;
  int get receivedBytes => _receivedBytes;
  int get totalBytes => _totalBytes;
  String? get downloadedApkPath => _downloadedApkPath;
  String? get errorMessage => _errorMessage;
  bool get autoCheckOnStartup => _autoCheckOnStartup;
  DateTime? get lastChecked => _lastChecked;

  bool get isChecking => _status == UpdateStatus.checking;
  bool get isDownloading => _status == UpdateStatus.downloading;
  bool get isUpdateAvailable => _status == UpdateStatus.available && (_updateInfo?.isUpdateAvailable ?? false);

  void toggleAutoCheck(bool value) {
    _autoCheckOnStartup = value;
    notifyListeners();
  }

  Future<void> checkForUpdates({bool isManual = false}) async {
    _status = UpdateStatus.checking;
    _errorMessage = null;
    notifyListeners();

    try {
      final info = await _updateService.checkForUpdate();
      _lastChecked = DateTime.now();

      if (info != null && info.isUpdateAvailable) {
        _updateInfo = info;
        _status = UpdateStatus.available;
      } else {
        _updateInfo = info;
        _status = UpdateStatus.upToDate;
      }
    } catch (e) {
      _status = UpdateStatus.error;
      _errorMessage = 'Could not check for updates. Check internet connection.';
    }

    notifyListeners();
  }

  Future<void> startDownloadAndInstall({Function(String error)? onError}) async {
    final info = _updateInfo;
    if (info == null || info.apkDownloadUrl == null) {
      if (info?.htmlUrl != null) {
        await _updateService.openReleasePage(info!.htmlUrl);
      }
      return;
    }

    _status = UpdateStatus.downloading;
    _progress = 0.0;
    _receivedBytes = 0;
    _totalBytes = info.apkSizeBytes ?? 0;
    _errorMessage = null;
    notifyListeners();

    try {
      final baseDir = await _updateService.getDownloadDirectoryPath();
      final destPath = '$baseDir/${info.apkFileName}';

      await for (final p in _updateService.downloadApk(info.apkDownloadUrl!, destPath)) {
        _progress = p.progress;
        _receivedBytes = p.receivedBytes;
        _totalBytes = p.totalBytes;
        notifyListeners();
      }

      _downloadedApkPath = destPath;
      _status = UpdateStatus.downloaded;
      notifyListeners();

      // Automatically launch the installer
      await installDownloadedApk();
    } catch (e) {
      _status = UpdateStatus.error;
      _errorMessage = 'Download failed: $e';
      onError?.call(_errorMessage!);
      notifyListeners();
    }
  }

  Future<bool> installDownloadedApk() async {
    if (_downloadedApkPath == null) return false;
    return await _updateService.installApk(_downloadedApkPath!);
  }

  Future<bool> openReleasePage() async {
    final url = _updateInfo?.htmlUrl ?? 'https://github.com/ulthan/shawarmathi-android/releases';
    return await _updateService.openReleasePage(url);
  }

  void dismissUpdate() {
    _status = UpdateStatus.idle;
    notifyListeners();
  }

  void resetStatus() {
    _status = UpdateStatus.idle;
    _errorMessage = null;
    notifyListeners();
  }
}
