import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/bill_receipt.dart';
import '../providers/sales_provider.dart';
import '../providers/security_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/bill_receipt_sheet.dart';
import '../widgets/pin_dialog.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedFilter = 'all';

  List<BillReceipt> _filterBills(List<BillReceipt> bills) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    switch (_selectedFilter) {
      case 'cash':
        return bills.where((b) => b.paymentType == 'CASH').toList();
      case 'upi':
        return bills.where((b) => b.paymentType == 'UPI').toList();
      case 'mixed':
        return bills.where((b) => b.paymentType == 'MIXED').toList();
      case 'today':
        return bills.where((b) => b.dateKey == todayStr).toList();
      case 'week':
        final daysToSubtract = now.weekday % 7;
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: daysToSubtract));
        final startOfWeekStr = DateFormat('yyyy-MM-dd').format(startOfWeek);
        return bills.where((b) => b.dateKey.compareTo(startOfWeekStr) >= 0).toList();
      case 'month':
        return bills.where((b) {
          final parts = b.dateKey.split('-');
          if (parts.length >= 2) {
            final y = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            return y == now.year && m == now.month;
          }
          return false;
        }).toList();
      default:
        return bills;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    final allSales = provider.sales;
    final allBills = BillReceipt.groupSalesIntoBills(allSales);
    final filteredBills = _filterBills(allBills);

    final totalFilteredRev = filteredBills.fold<int>(0, (sum, b) => sum + b.totalAmount);
    final totalFilteredQty = filteredBills.fold<int>(0, (sum, b) => sum + b.totalQuantity);

    final primary = AppTheme.primaryColor(context);

    final filters = [
      ('all', 'All', allBills.length),
      ('cash', 'Cash', allBills.where((b) => b.paymentType == 'CASH').length),
      ('upi', 'UPI', allBills.where((b) => b.paymentType == 'UPI').length),
      ('mixed', 'Mixed', allBills.where((b) => b.paymentType == 'MIXED').length),
      ('today', 'Today', allBills.where((b) => b.dateKey == DateFormat('yyyy-MM-dd').format(DateTime.now())).length),
      ('week', 'This Week', null),
      ('month', 'This Month', null),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales History',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '${filteredBills.length} bill${filteredBills.length == 1 ? '' : 's'} found',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
                  ),
                ],
              ),
              // Dynamic Total Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppTheme.dualGradient(context),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹$totalFilteredRev',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '$totalFilteredQty rolls',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Horizontal filter chips with dynamic count badges
        SizedBox(
          height: 48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final (key, label, count) = filters[index];
              final isSel = _selectedFilter == key;

              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _selectedFilter = key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSel
                        ? primary.withValues(alpha: AppTheme.isDark(context) ? 0.22 : 0.14)
                        : AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSel ? primary : AppTheme.borderColor(context),
                      width: isSel ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isSel ? primary : AppTheme.textSecondary(context),
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      if (count != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSel
                                ? primary
                                : AppTheme.borderColor(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSel
                                  ? Colors.white
                                  : AppTheme.textPrimary(context),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),

        // List of Billed Orders
        Expanded(
          child: filteredBills.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📋', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 10),
                      Text(
                        'No bills found.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredBills.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final bill = filteredBills[index];
                    return _HistoryBillCard(
                      bill: bill,
                      onDelete: () => _showDeleteBillDialog(context, bill),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showDeleteBillDialog(BuildContext context, BillReceipt bill) async {
    final security = context.read<SecurityProvider?>();
    if (security != null && !security.canDeleteBills) {
      final authorized = await PinDialog.prompt(
        context,
        title: 'Owner PIN Required',
        subtitle: 'Cashiers cannot delete sales without Owner authorization',
      );
      if (!authorized) return;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete Bill ${bill.receiptId}?',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary(context),
          ),
        ),
        content: Text(
          'Are you sure you want to delete this bill containing ${bill.items.length} item(s) (${bill.totalQuantity} rolls) for ₹${bill.totalAmount}?\n\nThis will remove all items billed in this order.',
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              if (bill.saleIds.isNotEmpty) {
                await context.read<SalesProvider>().deleteBill(bill.saleIds);
              } else {
                await context.read<SalesProvider>().deleteSale(bill.timestamp);
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted Bill ${bill.receiptId} (₹${bill.totalAmount})'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('Delete Bill'),
          ),
        ],
      ),
    );
  }
}

class _HistoryBillCard extends StatelessWidget {
  final BillReceipt bill;
  final VoidCallback onDelete;

  const _HistoryBillCard({
    required this.bill,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final primary = AppTheme.primaryColor(context);
    final isDark = AppTheme.isDark(context);

    Color payColor;
    IconData payIcon;
    switch (bill.paymentType.toUpperCase()) {
      case 'CASH':
        payColor = AppTheme.cashGreen;
        payIcon = Icons.payments_rounded;
        break;
      case 'UPI':
        payColor = AppTheme.upiBlue;
        payIcon = Icons.phone_android_rounded;
        break;
      default:
        payColor = AppTheme.mixedPurple;
        payIcon = Icons.shuffle_rounded;
    }

    final date = DateTime.fromMillisecondsSinceEpoch(bill.timestamp);
    final timeStr = DateFormat('d MMM yyyy, h:mm a').format(date);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => BillReceiptSheet.showReceipt(context, bill),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.borderColor(context),
          ),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Bill ID, Time, and Total Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Bill ${bill.receiptId}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₹${bill.totalAmount}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Itemized Billed Items Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardElevated : AppTheme.lightCardElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.borderColor(context).withValues(alpha: 0.6),
                ),
              ),
              child: Column(
                children: bill.items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  final isLast = idx == bill.items.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.itemName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${item.quantity} × ₹${item.unitPrice} = ₹${item.total}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Footer Row: Payment badge, items count, and actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: payColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(payIcon, size: 13, color: payColor),
                          const SizedBox(width: 4),
                          Text(
                            bill.paymentType,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: payColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${bill.items.length} item(s) • ${bill.totalQuantity} roll(s)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.receipt_long_rounded,
                        size: 22,
                        color: primary,
                      ),
                      tooltip: 'View & Share Bill (PDF)',
                      onPressed: () => BillReceiptSheet.showReceipt(context, bill),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppTheme.danger.withValues(alpha: 0.7),
                      ),
                      tooltip: 'Delete Bill',
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
