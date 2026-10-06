import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/sale_entity.dart';

class BackupResult {
  final List<SaleEntity> sales;
  final String exportedAt;
  final int totalRevenue;

  BackupResult({
    required this.sales,
    required this.exportedAt,
    required this.totalRevenue,
  });
}

class BackupService {
  static Future<bool> exportBackup(List<SaleEntity> sales) async {
    try {
      final now = DateTime.now();
      final dateFormatted = DateFormat('yyyy-MM-dd_HHmm').format(now);
      final totalRevenue = sales.fold<int>(0, (sum, s) => sum + s.total);

      final backupMap = {
        'app': 'Shawarmathi',
        'version': '1.0.0',
        'exportedAt': now.toIso8601String(),
        'salesCount': sales.length,
        'totalRevenue': totalRevenue,
        'sales': sales.map((s) => s.toMap()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupMap);

      final tempDir = await getTemporaryDirectory();
      final fileName = 'shawarmathi_backup_$dateFormatted.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(jsonString);

      final xFile = XFile(
        file.path,
        mimeType: 'application/json',
        name: fileName,
      );

      final shareResult = await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: 'Shawarmathi Sales Backup - $dateFormatted',
          text: 'Shawarmathi POS sales backup file ($dateFormatted). Contains ${sales.length} sales records.',
        ),
      );

      return shareResult.status == ShareResultStatus.success ||
          shareResult.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('Error exporting backup: $e');
      rethrow;
    }
  }

  static Future<BackupResult?> pickAndParseBackup() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (files.isEmpty) {
        return null;
      }

      final file = files.first;
      final content = await file.xFile.readAsString();

      final dynamic decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid backup format: root must be a JSON object');
      }

      final salesListRaw = decoded['sales'];
      if (salesListRaw is! List) {
        throw Exception('Invalid backup format: missing sales list');
      }

      final List<SaleEntity> parsedSales = [];
      for (final item in salesListRaw) {
        if (item is Map<String, dynamic>) {
          parsedSales.add(SaleEntity.fromMap(item));
        } else if (item is Map) {
          parsedSales.add(SaleEntity.fromMap(Map<String, dynamic>.from(item)));
        }
      }

      final totalRev = parsedSales.fold<int>(0, (sum, s) => sum + s.total);
      final exportedAt = decoded['exportedAt']?.toString() ?? 'Unknown date';

      return BackupResult(
        sales: parsedSales,
        exportedAt: exportedAt,
        totalRevenue: totalRev,
      );
    } catch (e) {
      debugPrint('Error picking or parsing backup: $e');
      rethrow;
    }
  }
}
