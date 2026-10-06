import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/sale_entity.dart';
import '../providers/sales_provider.dart';
import '../theme/app_theme.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _viewMonth;
  String? _selectedDateKey;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewMonth = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1, 1);
      _selectedDateKey = null;
    });
  }

  void _nextMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 1);
      _selectedDateKey = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SalesProvider>();
    final allSales = provider.sales;
    final primary = AppTheme.primaryColor(context);
    final secondary = AppTheme.secondaryColor(context);

    // Filter sales for the currently viewed month
    final monthSales = allSales.where((s) {
      final parts = s.dateKey.split('-');
      if (parts.length >= 2) {
        final y = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        return y == _viewMonth.year && m == _viewMonth.month;
      }
      return false;
    }).toList();

    final monthRev = monthSales.fold<int>(0, (sum, s) => sum + s.total);
    final monthQty = monthSales.fold<int>(0, (sum, s) => sum + s.quantity);

    // DateKey -> Total revenue
    final dateMap = <String, int>{};
    for (final sale in allSales) {
      dateMap[sale.dateKey] = (dateMap[sale.dateKey] ?? 0) + sale.total;
    }

    final maxRev = dateMap.values.fold<int>(1, (max, val) => val > max ? val : max);
    final monthTitle = DateFormat('MMMM yyyy').format(_viewMonth);

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

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
                  'Calendar',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary(context),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Sales heat-map & daily details',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
                ),
              ],
            ),
            // Month Volume Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                    '₹$monthRev',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$monthQty rolls',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Calendar Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor(context)),
            boxShadow: AppTheme.cardShadow(context),
          ),
          child: Column(
            children: [
              // Month Switcher
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                    onPressed: _prevMonth,
                  ),
                  Row(
                    children: [
                      Icon(Icons.calendar_month, size: 18, color: primary),
                      const SizedBox(width: 8),
                      Text(
                        monthTitle,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                    ],
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Day of week headers
              Row(
                children: const [
                  _DayHeader('Su'),
                  _DayHeader('Mo'),
                  _DayHeader('Tu'),
                  _DayHeader('We'),
                  _DayHeader('Th'),
                  _DayHeader('Fr'),
                  _DayHeader('Sa'),
                ],
              ),
              const SizedBox(height: 8),

              // Calendar Days Grid
              _buildDaysGrid(context, dateMap, maxRev, todayStr, primary, secondary),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Selected Day Details Panel
        if (_selectedDateKey != null)
          _buildDayDetailPanel(context, allSales, _selectedDateKey!),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDaysGrid(
    BuildContext context,
    Map<String, int> dateMap,
    int maxRev,
    String todayStr,
    Color primary,
    Color secondary,
  ) {
    final firstWeekday = _viewMonth.weekday % 7; // Sunday = 0
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;

    final totalCells = firstWeekday + daysInMonth;
    final rowCount = (totalCells / 7).ceil();
    final isDark = AppTheme.isDark(context);

    return Column(
      children: List.generate(rowCount, (row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNumber = cellIndex - firstWeekday + 1;

              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const Expanded(child: SizedBox(height: 42));
              }

              final dateStr =
                  '${_viewMonth.year}-${_viewMonth.month.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}';
              final rev = dateMap[dateStr] ?? 0;
              final ratio = rev > 0 ? (rev / maxRev).clamp(0.0, 1.0) : 0.0;

              double heatAlpha = 0.0;
              if (ratio > 0.8) {
                heatAlpha = 0.85;
              } else if (ratio > 0.6) {
                heatAlpha = 0.60;
              } else if (ratio > 0.4) {
                heatAlpha = 0.40;
              } else if (ratio > 0.2) {
                heatAlpha = 0.25;
              } else if (rev > 0) {
                heatAlpha = 0.14;
              }

              final isToday = dateStr == todayStr;
              final isSelected = dateStr == _selectedDateKey;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (_selectedDateKey == dateStr) {
                        _selectedDateKey = null;
                      } else {
                        _selectedDateKey = dateStr;
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 42,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(colors: [primary, secondary])
                          : (heatAlpha > 0
                              ? LinearGradient(
                                  colors: [
                                    primary.withValues(alpha: heatAlpha),
                                    secondary.withValues(alpha: heatAlpha * 0.8),
                                  ],
                                )
                              : null),
                      borderRadius: BorderRadius.circular(10),
                      border: isToday && !isSelected
                          ? Border.all(color: primary, width: 2)
                          : (isSelected
                              ? Border.all(color: Colors.white, width: 2)
                              : null),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          '$dayNumber',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isToday || isSelected
                                ? FontWeight.w900
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (heatAlpha > 0.5
                                    ? Colors.white
                                    : (isToday
                                        ? primary
                                        : AppTheme.textPrimary(context))),
                          ),
                        ),
                        if (rev > 0 && !isSelected)
                          Positioned(
                            bottom: 4,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: heatAlpha > 0.4
                                    ? Colors.white
                                    : (isDark ? primary : primary),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildDayDetailPanel(
    BuildContext context,
    List<SaleEntity> allSales,
    String dateKey,
  ) {
    final daySales = allSales.where((s) => s.dateKey == dateKey).toList();
    final primary = AppTheme.primaryColor(context);

    DateTime parsedDate;
    try {
      parsedDate = DateFormat('yyyy-MM-dd').parse(dateKey);
    } catch (_) {
      parsedDate = DateTime.now();
    }
    final formattedTitle = DateFormat('EEEE, d MMMM yyyy').format(parsedDate);

    final dayRev = daySales.fold<int>(0, (sum, s) => sum + s.total);
    final dayQty = daySales.fold<int>(0, (sum, s) => sum + s.quantity);

    final cashRev = daySales
        .where((s) => s.paymentType == 'CASH')
        .fold<int>(0, (sum, s) => sum + s.total);
    final upiRev = daySales
        .where((s) => s.paymentType == 'UPI')
        .fold<int>(0, (sum, s) => sum + s.total);
    final mixedRev = daySales
        .where((s) => s.paymentType == 'MIXED')
        .fold<int>(0, (sum, s) => sum + s.total);

    // Item breakdown
    final itemMap = <String, int>{};
    for (final sale in daySales) {
      itemMap[sale.itemName] = (itemMap[sale.itemName] ?? 0) + sale.total;
    }
    final sortedItems = itemMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📅 ', style: TextStyle(fontSize: 18)),
              Expanded(
                child: Text(
                  formattedTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _selectedDateKey = null),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (daySales.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                '😴 No sales recorded on this day.',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary(context)),
              ),
            )
          else ...[
            Row(
              children: [
                _buildStatTile(context, '$dayQty', 'Sold'),
                const SizedBox(width: 8),
                _buildStatTile(context, '₹$dayRev', 'Revenue'),
                const SizedBox(width: 8),
                _buildStatTile(context, '${daySales.length}', 'Orders'),
              ],
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (cashRev > 0)
                  _buildPaymentBadge('Cash ₹$cashRev', AppTheme.cashGreen),
                if (upiRev > 0)
                  _buildPaymentBadge('UPI ₹$upiRev', AppTheme.upiBlue),
                if (mixedRev > 0)
                  _buildPaymentBadge('Mixed ₹$mixedRev', AppTheme.mixedPurple),
              ],
            ),
            const SizedBox(height: 14),

            Text(
              'Item Breakdown',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: 6),

            ...sortedItems.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                    ),
                    Text(
                      '₹${entry.value}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, String value, String label) {
    final primary = AppTheme.primaryColor(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.cardElevatedColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  final String text;
  const _DayHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted(context),
          ),
        ),
      ),
    );
  }
}
