import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sale_entity.dart';
import '../providers/sales_provider.dart';
import '../theme/app_theme.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'month';

  List<SaleEntity> _filterSales(List<SaleEntity> sales) {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case 'week':
        final daysToSubtract = now.weekday % 7;
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: daysToSubtract));
        final startOfWeekStr =
            '${startOfWeek.year}-${startOfWeek.month.toString().padLeft(2, '0')}-${startOfWeek.day.toString().padLeft(2, '0')}';
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

    final totalRev = filtered.fold<int>(0, (sum, s) => sum + s.total);
    final totalQty = filtered.fold<int>(0, (sum, s) => sum + s.quantity);

    final cashRev = filtered
        .where((s) => s.paymentType == 'CASH')
        .fold<int>(0, (sum, s) => sum + s.total);
    final upiRev = filtered
        .where((s) => s.paymentType == 'UPI')
        .fold<int>(0, (sum, s) => sum + s.total);
    final mixedRev = filtered
        .where((s) => s.paymentType == 'MIXED')
        .fold<int>(0, (sum, s) => sum + s.total);

    // Group items by name -> (qty, rev)
    final Map<String, (int, int)> itemStats = {};
    for (final sale in filtered) {
      final prev = itemStats[sale.itemName] ?? (0, 0);
      itemStats[sale.itemName] = (prev.$1 + sale.quantity, prev.$2 + sale.total);
    }
    final sortedItemStats = itemStats.entries.toList()
      ..sort((a, b) => b.value.$2.compareTo(a.value.$2));

    final maxItemRev = sortedItemStats.isEmpty
        ? 1
        : sortedItemStats.first.value.$2;

    final primary = AppTheme.primaryColor(context);
    final secondary = AppTheme.secondaryColor(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reports & Insights',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary(context),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Revenue analytics and item rankings',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.insights_rounded, color: primary, size: 22),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Period filter chips
        Row(
          children: [
            _buildPeriodChip('month', 'This Month'),
            const SizedBox(width: 8),
            _buildPeriodChip('week', 'This Week'),
            const SizedBox(width: 8),
            _buildPeriodChip('all', 'All Time'),
          ],
        ),
        const SizedBox(height: 14),

        // Dynamic 3-Column Summary Card with Count-Up
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor(context)),
            boxShadow: AppTheme.cardShadow(context),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricColumn(
                context,
                totalRev,
                'Total Revenue',
                isCurrency: true,
                isHighlight: true,
              ),
              Container(
                width: 1,
                height: 44,
                color: AppTheme.borderColor(context),
              ),
              _buildMetricColumn(
                context,
                totalQty,
                'Rolls Sold',
              ),
              Container(
                width: 1,
                height: 44,
                color: AppTheme.borderColor(context),
              ),
              _buildMetricColumn(
                context,
                filtered.length,
                'Total Orders',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Payment Breakdown Card with Dynamic Progress Bars
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(20),
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
                    '💳 Payment Breakdown',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  if (totalRev > 0)
                    Text(
                      '₹$totalRev total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (totalRev > 0) ...[
                _buildPaymentBar(context, 'Cash', cashRev, totalRev, AppTheme.cashGreen),
                const SizedBox(height: 12),
                _buildPaymentBar(context, 'UPI', upiRev, totalRev, AppTheme.upiBlue),
                const SizedBox(height: 12),
                _buildPaymentBar(context, 'Mixed', mixedRev, totalRev, AppTheme.mixedPurple),
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No transaction data available for this period.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Item Performance Table with Proportional Ranking Bars
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(20),
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
                    '🥙 Top Selling Shawarmas',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  Text(
                    '${sortedItemStats.length} items',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMuted(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (sortedItemStats.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No item data recorded yet for this period.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
                  ),
                )
              else
                ...sortedItemStats.asMap().entries.map((entry) {
                  final index = entry.key;
                  final itemEntry = entry.value;
                  final itemName = itemEntry.key;
                  final (qty, rev) = itemEntry.value;
                  final barRatio = maxItemRev > 0 ? (rev / maxItemRev).clamp(0.0, 1.0) : 0.0;

                  String rankBadge = '${index + 1}';
                  if (index == 0) rankBadge = '🥇';
                  if (index == 1) rankBadge = '🥈';
                  if (index == 2) rankBadge = '🥉';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: index < 3
                                    ? primary.withValues(alpha: 0.15)
                                    : AppTheme.cardElevatedColor(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                rankBadge,
                                style: TextStyle(
                                  fontSize: index < 3 ? 14 : 11,
                                  fontWeight: FontWeight.w800,
                                  color: index < 3 ? primary : AppTheme.textSecondary(context),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    itemName,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary(context),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$qty rolls sold',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹$rev',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Proportional progress indicator
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: SizedBox(
                            height: 4,
                            child: Stack(
                              children: [
                                Container(color: AppTheme.cardElevatedColor(context)),
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: barRatio,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [primary, secondary],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildPeriodChip(String key, String label) {
    final isSel = _selectedPeriod == key;
    final primary = AppTheme.primaryColor(context);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _selectedPeriod = key),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel
                ? primary.withValues(alpha: AppTheme.isDark(context) ? 0.22 : 0.12)
                : AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSel ? primary : AppTheme.borderColor(context),
              width: isSel ? 1.6 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
              color: isSel ? primary : AppTheme.textSecondary(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricColumn(
    BuildContext context,
    int rawValue,
    String label, {
    bool isCurrency = false,
    bool isHighlight = false,
  }) {
    final primary = AppTheme.primaryColor(context);

    return Column(
      children: [
        TweenAnimationBuilder<double>(
          key: ValueKey('metric_${label}_$_selectedPeriod'),
          tween: Tween<double>(begin: 0, end: rawValue.toDouble()),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (context, val, child) {
            final formatted = isCurrency ? '₹${val.round()}' : '${val.round()}';
            return Text(
              formatted,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isHighlight ? primary : AppTheme.textPrimary(context),
                letterSpacing: -0.5,
              ),
            );
          },
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
        ),
      ],
    );
  }

  Widget _buildPaymentBar(
    BuildContext context,
    String label,
    int amount,
    int total,
    Color color,
  ) {
    final ratio = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    final percent = (ratio * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              '₹$amount ($percent%)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
