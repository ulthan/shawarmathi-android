import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_update_info.dart';

abstract class AppUpdateService {
  Future<AppUpdateInfo?> checkForUpdate();
  Stream<UpdateDownloadProgress> downloadApk(String url, String destinationPath);
  Future<bool> installApk(String filePath);
  Future<bool> openReleasePage(String url);
  Future<String> getDownloadDirectoryPath();
}

class GitHubAppUpdateService implements AppUpdateService {
  final String owner;
  final String repo;
  final http.Client? httpClient;

  GitHubAppUpdateService({
    this.owner = 'ulthan',
    this.repo = 'shawarmathi-android',
    this.httpClient,
  });

  http.Client get client => httpClient ?? http.Client();

  @override
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      PackageInfo? packageInfo;
      try {
        packageInfo = await PackageInfo.fromPlatform();
      } catch (_) {
        // Fallback for desktop/test platforms
      }

      final currentVersion = packageInfo?.version ?? '1.0.0';
      final currentBuildNumber = int.tryParse(packageInfo?.buildNumber ?? '1') ?? 1;

      final url = Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');
      final response = await client.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'ShawarmathiPOS-UpdateChecker',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final tagName = data['tag_name'] as String? ?? '';
        final releaseTitle = data['name'] as String? ?? tagName;
        final releaseNotes = data['body'] as String? ?? '';
        final htmlUrl = data['html_url'] as String? ?? 'https://github.com/$owner/$repo/releases';
        final publishedStr = data['published_at'] as String?;
        final publishedAt = publishedStr != null ? DateTime.tryParse(publishedStr) : null;

        String? apkDownloadUrl;
        String apkFileName = 'app-release.apk';
        int? apkSizeBytes;

        final assets = (data['assets'] as List<dynamic>?) ?? [];
        for (final asset in assets) {
          if (asset is Map<String, dynamic>) {
            final name = (asset['name'] as String? ?? '').toLowerCase();
            if (name.endsWith('.apk')) {
              apkDownloadUrl = asset['browser_download_url'] as String?;
              apkFileName = asset['name'] as String? ?? 'app-release.apk';
              apkSizeBytes = asset['size'] as int?;
              break;
            }
          }
        }

        // Clean tag name into semver
        var cleanTag = tagName.startsWith('v') || tagName.startsWith('V')
            ? tagName.substring(1)
            : tagName;
        int latestBuildNumber = 1;
        if (cleanTag.contains('+')) {
          final parts = cleanTag.split('+');
          cleanTag = parts.first;
          latestBuildNumber = int.tryParse(parts.last) ?? 1;
        }

        return AppUpdateInfo(
          latestVersion: cleanTag.isEmpty ? currentVersion : cleanTag,
          latestBuildNumber: latestBuildNumber,
          currentVersion: currentVersion,
          currentBuildNumber: currentBuildNumber,
          releaseTitle: releaseTitle,
          releaseNotes: releaseNotes,
          apkDownloadUrl: apkDownloadUrl,
          apkFileName: apkFileName,
          apkSizeBytes: apkSizeBytes,
          htmlUrl: htmlUrl,
          publishedAt: publishedAt,
        );
      } else if (response.statusCode == 404) {
        // No releases published yet on the repository
        return AppUpdateInfo(
          latestVersion: currentVersion,
          latestBuildNumber: currentBuildNumber,
          currentVersion: currentVersion,
          currentBuildNumber: currentBuildNumber,
          releaseTitle: 'Up to Date',
          releaseNotes: 'No new updates published yet.',
          apkDownloadUrl: null,
          apkFileName: 'app-release.apk',
          apkSizeBytes: null,
          htmlUrl: 'https://github.com/$owner/$repo',
        );
      }
    } catch (_) {
      // Re-throw or return null on network failure
      rethrow;
    }
    return null;
  }

  @override
  Stream<UpdateDownloadProgress> downloadApk(String url, String destinationPath) async* {
    final request = http.Request('GET', Uri.parse(url));
    request.headers['User-Agent'] = 'ShawarmathiPOS-UpdateDownloader';

    final response = await client.send(request);
    if (response.statusCode != 200) {
      throw Exception('Failed to download update: HTTP ${response.statusCode}');
    }

    final totalBytes = response.contentLength ?? 0;
    int receivedBytes = 0;

    final file = File(destinationPath);
    if (await file.exists()) {
      await file.delete();
    }
    final sink = file.openWrite();

    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        final progress = totalBytes > 0 ? (receivedBytes / totalBytes) : 0.0;
        yield UpdateDownloadProgress(
          progress: progress,
          receivedBytes: receivedBytes,
          totalBytes: totalBytes,
        );
      }
    } finally {
      await sink.flush();
      await sink.close();
    }
  }

  @override
  Future<bool> installApk(String filePath) async {
    try {
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );
      return result.type == ResultType.done;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> openReleasePage(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }

  @override
  Future<String> getDownloadDirectoryPath() async {
    try {
      final dir = await getTemporaryDirectory();
      return dir.path;
    } catch (_) {
      return Directory.systemTemp.path;
    }
  }
}

/// Fake implementation for tests
class FakeAppUpdateService implements AppUpdateService {
  AppUpdateInfo? nextUpdateInfo;
  bool shouldThrow = false;
  bool installResult = true;

  FakeAppUpdateService({this.nextUpdateInfo});

  @override
  Future<String> getDownloadDirectoryPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<AppUpdateInfo?> checkForUpdate() async {
    if (shouldThrow) {
      throw Exception('Network unreachable');
    }
    return nextUpdateInfo ??
        const AppUpdateInfo(
          latestVersion: '1.0.0',
          latestBuildNumber: 1,
          currentVersion: '1.0.0',
          currentBuildNumber: 1,
          releaseTitle: 'Up to Date',
          releaseNotes: 'You are on the latest version.',
          apkDownloadUrl: null,
          apkFileName: 'app-release.apk',
          apkSizeBytes: null,
          htmlUrl: 'https://github.com/ulthan/shawarmathi-android',
        );
  }

  @override
  Stream<UpdateDownloadProgress> downloadApk(String url, String destinationPath) async* {
    yield const UpdateDownloadProgress(progress: 0.5, receivedBytes: 30000000, totalBytes: 60000000);
    yield const UpdateDownloadProgress(progress: 1.0, receivedBytes: 60000000, totalBytes: 60000000);
  }

  @override
  Future<bool> installApk(String filePath) async {
    return installResult;
  }

  @override
  Future<bool> openReleasePage(String url) async {
    return true;
  }
}
