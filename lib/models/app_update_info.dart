class AppUpdateInfo {
  final String latestVersion;
  final int latestBuildNumber;
  final String currentVersion;
  final int currentBuildNumber;
  final String releaseTitle;
  final String releaseNotes;
  final String? apkDownloadUrl;
  final String apkFileName;
  final int? apkSizeBytes;
  final String htmlUrl;
  final DateTime? publishedAt;

  const AppUpdateInfo({
    required this.latestVersion,
    required this.latestBuildNumber,
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.releaseTitle,
    required this.releaseNotes,
    required this.apkDownloadUrl,
    required this.apkFileName,
    required this.apkSizeBytes,
    required this.htmlUrl,
    this.publishedAt,
  });

  bool get isUpdateAvailable {
    final vCompare = compareVersions(latestVersion, currentVersion);
    if (vCompare > 0) return true;
    if (vCompare == 0 && latestBuildNumber > currentBuildNumber) return true;
    return false;
  }

  String get formattedSize {
    if (apkSizeBytes == null || apkSizeBytes! <= 0) return '';
    final mb = apkSizeBytes! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  /// Compares semantic versions (e.g. "1.0.1" vs "1.0.0").
  /// Returns > 0 if v1 > v2, < 0 if v1 < v2, and 0 if equal.
  static int compareVersions(String v1, String v2) {
    final cleanV1 = _cleanVersion(v1);
    final cleanV2 = _cleanVersion(v2);

    final parts1 = cleanV1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = cleanV2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (int i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  static String _cleanVersion(String version) {
    var v = version.trim();
    if (v.startsWith('v') || v.startsWith('V')) {
      v = v.substring(1);
    }
    // Remove build number if present (e.g., 1.0.0+1 -> 1.0.0)
    if (v.contains('+')) {
      v = v.split('+').first;
    }
    // Remove prerelease tags if present (e.g., 1.0.0-beta -> 1.0.0)
    if (v.contains('-')) {
      v = v.split('-').first;
    }
    return v;
  }
}

class UpdateDownloadProgress {
  final double progress; // 0.0 to 1.0
  final int receivedBytes;
  final int totalBytes;

  const UpdateDownloadProgress({
    required this.progress,
    required this.receivedBytes,
    required this.totalBytes,
  });

  String get formattedProgress {
    final pct = (progress * 100).clamp(0, 100).toStringAsFixed(0);
    final receivedMb = (receivedBytes / (1024 * 1024)).toStringAsFixed(1);
    final totalMb = totalBytes > 0 ? (totalBytes / (1024 * 1024)).toStringAsFixed(1) : '?';
    return '$pct% ($receivedMb MB / $totalMb MB)';
  }
}
