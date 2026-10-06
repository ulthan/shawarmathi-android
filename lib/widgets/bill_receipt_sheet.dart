import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill_receipt.dart';
import '../models/sale_entity.dart';
import '../services/receipt_service.dart';
import '../theme/app_theme.dart';

class BillReceiptSheet extends StatelessWidget {
  final BillReceipt receipt;

  const BillReceiptSheet({super.key, required this.receipt});

  factory BillReceiptSheet.fromSale({Key? key, required SaleEntity sale}) {
    return BillReceiptSheet(key: key, receipt: BillReceipt.fromSales([sale]));
  }

  factory BillReceiptSheet.fromSales({Key? key, required List<SaleEntity> sales}) {
    return BillReceiptSheet(key: key, receipt: BillReceipt.fromSales(sales));
  }

  static Future<void> showReceipt(BuildContext context, BillReceipt receipt) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BillReceiptSheet(receipt: receipt),
    );
  }

  static Future<void> showSales(BuildContext context, List<SaleEntity> sales) {
    if (sales.isEmpty) return Future.value();
    return showReceipt(context, BillReceipt.fromSales(sales));
  }

  static Future<void> show(
    BuildContext context, [
    dynamic target,
    List<SaleEntity>? sales,
  ]) {
    if (target is BillReceipt) {
      return showReceipt(context, target);
    }
    if (target is List<SaleEntity> && target.isNotEmpty) {
      return showReceipt(context, BillReceipt.fromSales(target));
    }
    if (target is SaleEntity) {
      return showReceipt(context, BillReceipt.fromSales([target]));
    }
    if (sales != null && sales.isNotEmpty) {
      return showReceipt(context, BillReceipt.fromSales(sales));
    }
    return Future.value();
  }

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor(context);
    final isDark = AppTheme.isDark(context);
    final dateTime = DateTime.fromMillisecondsSinceEpoch(receipt.timestamp);
    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
    final receiptId = receipt.receiptId.startsWith('#')
        ? receipt.receiptId
        : '#${receipt.receiptId}';

    Color paymentColor;
    IconData paymentIcon;
    switch (receipt.paymentType.toUpperCase()) {
      case 'CASH':
        paymentColor = AppTheme.cashGreen;
        paymentIcon = Icons.payments_rounded;
        break;
      case 'UPI':
        paymentColor = AppTheme.upiBlue;
        paymentIcon = Icons.phone_android_rounded;
        break;
      default:
        paymentColor = AppTheme.mixedPurple;
        paymentIcon = Icons.shuffle_rounded;
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: AppTheme.cardShadow(context),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 44,
            height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppTheme.textMuted(context).withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Scrollable Digital Bill Card
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCardElevated : AppTheme.lightCardElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Store Header with Official Logo
                    Center(
                      child: Column(
                        children: [
                          Container(
                            height: 64,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: primary.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                              'assets/images/logo.jpg',
                              fit: BoxFit.contain,
                              errorBuilder: (ctx, err, st) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.dualGradient(context),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.receipt_rounded, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SHAWARMATHI',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.textPrimary(context),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Arabian Fast Casual • Authentic Flavors',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted(context),
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Receipt ID & Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bill $receiptId',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDottedLine(context),
                    const SizedBox(height: 12),

                    // Items Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ITEMS ORDERED (${receipt.items.length})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMuted(context),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'AMOUNT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textMuted(context),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Consolidated Chosen Items List
                    ...receipt.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${index + 1}. ${item.itemName}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.textPrimary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.quantity} × ₹${item.unitPrice}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${item.total}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textPrimary(context),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 12),
                    _buildDottedLine(context),
                    const SizedBox(height: 12),

                    // Total Count & Total Paid
                    if (receipt.items.length > 1) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Items',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted(context),
                            ),
                          ),
                          Text(
                            '${receipt.items.length} items (${receipt.totalQuantity} rolls)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'TOTAL BILL',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textSecondary(context),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          '₹${receipt.totalAmount}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Payment badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(paymentIcon, size: 16, color: paymentColor),
                            const SizedBox(width: 6),
                            Text(
                              'Paid via ${receipt.paymentType.toUpperCase()}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: paymentColor,
                              ),
                            ),
                          ],
                        ),
                        if (receipt.paymentType.toUpperCase() == 'MIXED')
                          Text(
                            'Cash: ₹${receipt.cashAmount} | UPI: ₹${receipt.upiAmount}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textMuted(context),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDottedLine(context),
                    const SizedBox(height: 10),

                    Center(
                      child: Text(
                        'Shukran for dining at Shawarmathi! 🌯',
                        style: TextStyle(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: AppTheme.textMuted(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Action Buttons: PDF (Bluetooth, Print, WhatsApp) + Text + Copy
          Column(
            children: [
              // Primary PDF Share Button
              Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: AppTheme.dualGradient(context),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => ReceiptService.shareBillPdf(receipt),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Share PDF Bill (Bluetooth / Print)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Secondary Row: Copy & Plain Text Share
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ReceiptService.copyBillToClipboard(receipt);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Bill text copied to clipboard!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary(context),
                        side: BorderSide(color: AppTheme.borderColor(context)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => ReceiptService.shareBillReceipt(receipt),
                      icon: const Icon(Icons.text_snippet_rounded, size: 16),
                      label: const Text('Share Text'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary(context),
                        side: BorderSide(color: AppTheme.borderColor(context)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDottedLine(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashHeight = 1.0;
        const dashSpace = 3.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.borderColor(context),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
