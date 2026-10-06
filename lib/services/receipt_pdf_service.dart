import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/bill_receipt.dart';

class ReceiptPdfService {
  static Future<Uint8List> generatePdf(BillReceipt receipt) async {
    final pdf = pw.Document(
      title: 'Shawarmathi Bill ${receipt.receiptId}',
      author: 'Shawarmathi',
    );

    pw.MemoryImage? logoImage;
    try {
      final ByteData logoData = await rootBundle.load('assets/images/logo.jpg');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    final dateTime = DateTime.fromMillisecondsSinceEpoch(receipt.timestamp);
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    final receiptId = receipt.receiptId.startsWith('#')
        ? receipt.receiptId
        : '#${receipt.receiptId}';

    // POS 80mm roll width format with dynamic calculated height
    final double calculatedHeight = (150.0 +
            (receipt.items.length * 15.0) +
            (receipt.items.length > 1 ? 16.0 : 0.0) +
            (receipt.paymentType.toUpperCase() == 'MIXED' ? 14.0 : 0.0))
        .clamp(160.0, 450.0);

    final pageFormat = PdfPageFormat(
      80 * PdfPageFormat.mm,
      calculatedHeight * PdfPageFormat.mm,
      marginAll: 4 * PdfPageFormat.mm,
    );

    const saffron = PdfColor.fromInt(0xFFE65100);
    const darkText = PdfColor.fromInt(0xFF1E1E24);
    const mutedText = PdfColor.fromInt(0xFF5A5A65);
    const borderColor = PdfColor.fromInt(0xFFCCCCCC);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Logo Header
                if (logoImage != null)
                  pw.Center(
                    child: pw.Container(
                      height: 46,
                      margin: const pw.EdgeInsets.only(bottom: 6),
                      child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                    ),
                  )
                else ...[
                  pw.Center(
                    child: pw.Text(
                      'SHAWARMATHI',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: saffron,
                      ),
                    ),
                  ),
                  pw.Center(
                    child: pw.Text(
                      'The Real Arabian Taste',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontStyle: pw.FontStyle.italic,
                        color: mutedText,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 4),
                ],

                pw.Center(
                  child: pw.Text(
                    'Arabian Fast Casual • Authentic Flavors',
                    style: const pw.TextStyle(fontSize: 7.5, color: mutedText),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.8, color: borderColor),
                pw.SizedBox(height: 4),

                // Bill ID & Date
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Bill $receiptId',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    pw.Text(
                      dateStr,
                      style: const pw.TextStyle(fontSize: 8, color: mutedText),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.8, color: borderColor),
                pw.SizedBox(height: 4),

                // Table Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      flex: 5,
                      child: pw.Text(
                        'ITEM',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          color: mutedText,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(
                        'QTY x RATE',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          color: mutedText,
                        ),
                      ),
                    ),
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(
                        'TOTAL',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          color: mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 3),
                pw.Divider(thickness: 0.5, color: borderColor),
                pw.SizedBox(height: 3),

                // Item Rows
                ...receipt.items.asMap().entries.map((entry) {
                  final i = entry.key + 1;
                  final item = entry.value;
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 2),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Expanded(
                          flex: 5,
                          child: pw.Text(
                            '$i. ${item.itemName}',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            '${item.quantity} x Rs.${item.unitPrice}',
                            textAlign: pw.TextAlign.center,
                            style: const pw.TextStyle(fontSize: 7.5, color: mutedText),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            'Rs.${item.total}',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              fontWeight: pw.FontWeight.bold,
                              color: darkText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.8, color: borderColor),
                pw.SizedBox(height: 4),

                // Multi-item summary
                if (receipt.items.length > 1) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total Items',
                        style: const pw.TextStyle(fontSize: 8, color: mutedText),
                      ),
                      pw.Text(
                        '${receipt.items.length} items (${receipt.totalQuantity} rolls)',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                ],

                // Grand Total
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL BILL',
                      style: pw.TextStyle(
                        fontSize: 10.5,
                        fontWeight: pw.FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    pw.Text(
                      'Rs.${receipt.totalAmount}',
                      style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: saffron,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),

                // Payment Mode & Split
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Paid via ${receipt.paymentType.toUpperCase()}',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    if (receipt.paymentType.toUpperCase() == 'MIXED')
                      pw.Text(
                        'Cash: Rs.${receipt.cashAmount} | UPI: Rs.${receipt.upiAmount}',
                        style: const pw.TextStyle(fontSize: 7.5, color: mutedText),
                      ),
                  ],
                ),

                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.8, color: borderColor),
                pw.SizedBox(height: 6),

                // Footer
                pw.Center(
                  child: pw.Text(
                    'Shukran for dining at Shawarmathi!',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontStyle: pw.FontStyle.italic,
                      fontWeight: pw.FontWeight.bold,
                      color: darkText,
                    ),
                  ),
                ),
                pw.Center(
                  child: pw.Text(
                    'Visit us again for Arabian flavor.',
                    style: const pw.TextStyle(fontSize: 7, color: mutedText),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<File> savePdfToFile(BillReceipt receipt) async {
    final bytes = await generatePdf(receipt);
    final tempDir = await getTemporaryDirectory();
    final cleanId = receipt.receiptId.replaceAll('#', '').trim();
    final file = File('${tempDir.path}/shawarmathi_bill_REC_$cleanId.pdf');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static Future<void> shareBillPdf(BillReceipt receipt) async {
    final file = await savePdfToFile(receipt);
    final cleanId = receipt.receiptId.replaceAll('#', '').trim();
    final xFile = XFile(
      file.path,
      mimeType: 'application/pdf',
      name: 'shawarmathi_bill_REC_$cleanId.pdf',
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [xFile],
        subject: 'Shawarmathi Bill (Receipt #$cleanId)',
        text: 'Here is your Shawarmathi bill (Receipt #$cleanId). Shukran!',
      ),
    );
  }
}
