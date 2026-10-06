import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/bill_receipt.dart';
import '../models/sale_entity.dart';
import 'receipt_pdf_service.dart';

class ReceiptService {
  static String formatBillReceiptText(BillReceipt receipt) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(receipt.timestamp);
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    final receiptId = receipt.receiptId.startsWith('#')
        ? 'REC-${receipt.receiptId}'
        : 'REC-#${receipt.receiptId}';

    final buffer = StringBuffer();
    buffer.writeln('================================');
    buffer.writeln('          SHAWARMATHI');
    buffer.writeln('     The Real Arabian Taste');
    buffer.writeln('================================');
    buffer.writeln('Receipt ID : $receiptId');
    buffer.writeln('Date & Time: $dateStr');
    buffer.writeln('--------------------------------');
    buffer.writeln('ITEMS ORDERED:');
    for (var i = 0; i < receipt.items.length; i++) {
      final item = receipt.items[i];
      buffer.writeln('${i + 1}. ${item.itemName}');
      buffer.writeln('   ${item.quantity} × ₹${item.unitPrice} = ₹${item.total}');
    }
    buffer.writeln('--------------------------------');
    if (receipt.items.length > 1) {
      buffer.writeln('Total Items  : ${receipt.items.length} items (${receipt.totalQuantity} rolls)');
    }
    buffer.writeln('TOTAL AMOUNT : ₹${receipt.totalAmount}');
    buffer.writeln('Payment Mode : ${receipt.paymentType.toUpperCase()}');

    if (receipt.paymentType.toUpperCase() == 'MIXED') {
      buffer.writeln('  - Cash : ₹${receipt.cashAmount}');
      buffer.writeln('  - UPI  : ₹${receipt.upiAmount}');
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('Thank you for dining with us!');
    buffer.writeln('Visit us again for Arabian flavor.');
    buffer.writeln('================================');

    return buffer.toString();
  }

  static String formatReceiptText(SaleEntity sale) {
    return formatBillReceiptText(BillReceipt.fromSales([sale]));
  }

  static Future<void> shareBillReceipt(BillReceipt receipt) async {
    final text = formatBillReceiptText(receipt);
    final cleanId = receipt.receiptId.replaceAll('#', '').trim();
    final fileName = 'receipt_REC_$cleanId.txt';

    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsString(text);

      final xFile = XFile(
        file.path,
        mimeType: 'text/plain',
        name: fileName,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: 'Bill from Shawarmathi (Receipt #$cleanId)',
          text: text,
        ),
      );
    } catch (_) {
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Bill from Shawarmathi (Receipt #$cleanId)',
        ),
      );
    }
  }

  static Future<void> shareReceipt(SaleEntity sale) async {
    await shareBillReceipt(BillReceipt.fromSales([sale]));
  }

  static Future<void> copyBillToClipboard(BillReceipt receipt) async {
    final text = formatBillReceiptText(receipt);
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<void> copyToClipboard(SaleEntity sale) async {
    await copyBillToClipboard(BillReceipt.fromSales([sale]));
  }

  static Future<void> shareBillPdf(BillReceipt receipt) async {
    await ReceiptPdfService.shareBillPdf(receipt);
  }

  static Future<File> saveBillPdfToFile(BillReceipt receipt) async {
    return ReceiptPdfService.savePdfToFile(receipt);
  }
}
