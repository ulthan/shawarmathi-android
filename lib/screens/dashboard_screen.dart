import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/bill_receipt.dart';
import '../models/sale_entity.dart';
import '../providers/sales_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/add_sale_sheet.dart';
import '../widgets/bill_receipt_sheet.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int index)? onNavigate;

  const DashboardScreen({super.key, this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedPeriod = 'today';

  List<SaleEntity> _filterSales(List<SaleEntity> sales) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    switch (_selectedPeriod) {
      case 'today':
        return sales.where((s) => s.dateKey == todayStr).toList();
      case 'week':
        final daysToSubtract = now.weekday % 7;
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: daysToSubtract));
        final startOfWeekStr = DateFormat('yyyy-MM-dd').format(startOfWeek);
        return sales.where((s) => s.dateKey.compareTo(startOfWeekStr) >= 0).toList();
      case 'month':
        return sales.where((s) {
          final parts = s.dateKey.split('-');
          if (parts.length >= 2) {
            final y = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            return y == now.year && m == now.month;
          }
          return false;
        }).toList();
      default:
        return sales;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    final allSales = provider.sales;
    final filtered = _filterSales(allSales);

    final totalQty = filtered.fold<int>(0, (sum, s) => sum + s.quantity);
    final totalRev = filtered.fold<int>(0, (sum, s) => sum + s.total);

    final allBills = BillReceipt.groupSalesIntoBills(allSales);
    final filteredBills = BillReceipt.groupSalesIntoBills(filtered);
    final avgAov = filteredBills.isEmpty ? 0 : (totalRev / filteredBills.length).round();

    final cashRev = filtered
        .where((s) => s.paymentType == 'CASH')
        .fold<int>(0, (sum, s) => sum + s.total);
    final cashCnt = filteredBills.where((b) => b.paymentType == 'CASH').length;

    final upiRev = filtered
        .where((s) => s.paymentType == 'UPI')
        .fold<int>(0, (sum, s) => sum + s.total);
    final upiCnt = filteredBills.where((b) => b.paymentType == 'UPI').length;

    final mixedRev = filtered
        .where((s) => s.paymentType == 'MIXED')
        .fold<int>(0, (sum, s) => sum + s.total);
    final mixedCnt = filteredBills.where((b) => b.paymentType == 'MIXED').length;

    final recentBills = allBills.take(6).toList();
    final primary = AppTheme.primaryColor(context);
    final secondary = AppTheme.secondaryColor(context);

    return RefreshIndicator(
      onRefresh: () => provider.loadSales(),
      color: primary,
      backgroundColor: AppTheme.cardColor(context),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Dynamic Period Selector Tabs
          Row(
            children: [
              _buildPeriodChip('today', 'Today', Icons.today_rounded),
              const SizedBox(width: 8),
              _buildPeriodChip('week', 'This Week', Icons.date_range_rounded),
              const SizedBox(width: 8),
              _buildPeriodChip('month', 'This Month', Icons.calendar_month_rounded),
            ],
          ),
          const SizedBox(height: 14),

          // 5. Dynamic Revenue & Shawarmas Sold Card with Count-Up Animations
          _buildRevenueCard(context, totalQty, totalRev, avgAov, primary, secondary),
          const SizedBox(height: 14),

          // 6. Dynamic Payment Breakdown Bar
          if (totalRev > 0) ...[
            _buildPaymentBreakdownBar(context, cashRev, upiRev, mixedRev, totalRev),
            const SizedBox(height: 14),
          ],

          // 7. Payment Cards
          Row(
            children: [
              Expanded(
                child: _buildPaymentSummaryCard(
                  context: context,
                  emoji: '💵',
                  label: 'Cash',
                  amount: cashRev,
                  countText: '$cashCnt sales',
                  color: AppTheme.cashGreen,
                  totalRevenue: totalRev,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPaymentSummaryCard(
                  context: context,
                  emoji: '📲',
                  label: 'UPI',
                  amount: upiRev,
                  countText: '$upiCnt sales',
                  color: AppTheme.upiBlue,
                  totalRevenue: totalRev,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildPaymentSummaryCard(
            context: context,
            emoji: '🔀',
            label: 'Mixed (Cash + UPI)',
            amount: mixedRev,
            countText: '$mixedCnt sales',
            color: AppTheme.mixedPurple,
            totalRevenue: totalRev,
          ),
          const SizedBox(height: 22),

          // 8. Recent Sales Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Sales',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              if (recentBills.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Last ${recentBills.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Recent Bills List or Empty State
          if (recentBills.isEmpty)
            _buildEmptyState(context)
          else
            ...recentBills.map((bill) => _buildBillRow(context, bill)),
          const SizedBox(height: 30),
        ],
      ),
    );
  }


  Widget _buildPeriodChip(String key, String label, IconData icon) {
    final isSel = _selectedPeriod == key;
    final primary = AppTheme.primaryColor(context);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _selectedPeriod = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel
                ? primary.withValues(alpha: AppTheme.isDark(context) ? 0.22 : 0.12)
                : AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSel ? primary : AppTheme.borderColor(context),
              width: isSel ? 1.8 : 1,
            ),
            boxShadow: isSel ? AppTheme.cardShadow(context) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSel ? primary : AppTheme.textSecondary(context),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                  color: isSel ? primary : AppTheme.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCard(
    BuildContext context,
    int totalQty,
    int totalRev,
    int avgAov,
    Color primary,
    Color secondary,
  ) {
    final isDark = AppTheme.isDark(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: primary.withValues(alpha: isDark ? 0.35 : 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.25 : 0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Shawarmas Sold Counter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🥙', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          'Shawarmas Sold',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Animated count
                    TweenAnimationBuilder<double>(
                      key: ValueKey('qty_$_selectedPeriod'),
                      tween: Tween<double>(begin: 0, end: totalQty.toDouble()),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, val, child) {
                        return Text(
                          '${val.round()}',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: primary,
                            letterSpacing: -0.5,
                          ),
                        );
                      },
                    ),
                    Text(
                      _selectedPeriod == 'today'
                          ? 'Today’s volume'
                          : (_selectedPeriod == 'week'
                              ? 'This week total'
                              : 'This month total'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted(context),
                      ),
                    ),
                  ],
                ),
              ),

              // Total Revenue Counter
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Text('💰', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        'Total Revenue',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Animated revenue count
                  TweenAnimationBuilder<double>(
                    key: ValueKey('rev_$_selectedPeriod'),
                    tween: Tween<double>(begin: 0, end: totalRev.toDouble()),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) {
                      return Text(
                        '₹${val.round()}',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: primary,
                          letterSpacing: -0.5,
                        ),
                      );
                    },
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Avg ₹$avgAov / order',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: secondary,
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

  Widget _buildPaymentBreakdownBar(
    BuildContext context,
    int cash,
    int upi,
    int mixed,
    int total,
  ) {
    final cashPct = ((cash / total) * 100).round();
    final upiPct = ((upi / total) * 100).round();
    final mixedPct = (100 - cashPct - upiPct).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Mix Distribution',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              Text(
                'Live Ratios',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (cash > 0)
                    Expanded(
                      flex: cash,
                      child: Container(
                        color: AppTheme.cashGreen,
                      ),
                    ),
                  if (upi > 0)
                    Expanded(
                      flex: upi,
                      child: Container(
                        color: AppTheme.upiBlue,
                      ),
                    ),
                  if (mixed > 0)
                    Expanded(
                      flex: mixed,
                      child: Container(
                        color: AppTheme.mixedPurple,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRatioBadge('Cash', '$cashPct%', AppTheme.cashGreen),
              _buildRatioBadge('UPI', '$upiPct%', AppTheme.upiBlue),
              _buildRatioBadge('Mixed', '$mixedPct%', AppTheme.mixedPurple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatioBadge(String label, String pct, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $pct',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummaryCard({
    required BuildContext context,
    required String emoji,
    required String label,
    required int amount,
    required String countText,
    required Color color,
    required int totalRevenue,
  }) {
    final pct = totalRevenue == 0 ? 0 : ((amount / totalRevenue) * 100).round();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppTheme.isDark(context) ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              if (totalRevenue > 0 && amount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$pct%',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '₹$amount',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            countText,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final primary = AppTheme.primaryColor(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        children: [
          const Text('🥙', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(
            'No sales recorded yet.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap below to record your first shawarma sale!',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => AddSaleSheet.show(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add First Sale'),
          ),
        ],
      ),
    );
  }

  Widget _buildBillRow(BuildContext context, BillReceipt bill) {
    Color payColor;
    String payEmoji;
    switch (bill.paymentType.toUpperCase()) {
      case 'CASH':
        payColor = AppTheme.cashGreen;
        payEmoji = '💵';
        break;
      case 'UPI':
        payColor = AppTheme.upiBlue;
        payEmoji = '📲';
        break;
      case 'MIXED':
        payColor = AppTheme.mixedPurple;
        payEmoji = '🔀';
        break;
      default:
        payColor = AppTheme.primaryColor(context);
        payEmoji = '💰';
    }

    final date = DateTime.fromMillisecondsSinceEpoch(bill.timestamp);
    final timeStr = DateFormat('d MMM, h:mm a').format(date);

    final String itemSummary = bill.items.length == 1
        ? bill.items.first.itemName
        : '${bill.items.first.itemName} +${bill.items.length - 1} more';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => BillReceiptSheet.showReceipt(context, bill),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderColor(context)),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: payColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(payEmoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemSummary,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary(context),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: payColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          bill.paymentType,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: payColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${bill.items.length} item(s) (${bill.totalQuantity} rolls) · $timeStr',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '₹${bill.totalAmount}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.receipt_long_rounded,
              size: 18,
              color: AppTheme.primaryColor(context).withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

}
