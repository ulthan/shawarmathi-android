import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bill_receipt.dart';
import '../models/menu_item.dart';
import '../providers/menu_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/security_provider.dart';
import '../screens/menu_management_screen.dart';
import '../theme/app_theme.dart';
import 'bill_receipt_sheet.dart';
import 'pin_dialog.dart';

class AddSaleSheet extends StatefulWidget {
  const AddSaleSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddSaleSheet(),
    );
  }

  @override
  State<AddSaleSheet> createState() => _AddSaleSheetState();
}

class _AddSaleSheetState extends State<AddSaleSheet> {
  final Map<int, int> _itemQuantities = {};
  String _selectedCategory = 'All';
  PaymentType _paymentType = PaymentType.cash;

  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _upiController = TextEditingController();

  List<MenuItem> get _menuItems {
    try {
      final mp = Provider.of<MenuProvider>(context, listen: true);
      return mp.items;
    } catch (_) {
      return defaultMenuItems;
    }
  }

  List<String> get _categories {
    final cats = _menuItems.map((e) => e.category).toSet().toList()..sort();
    return ['All', ...cats];
  }

  List<MenuItem> get _filteredItems {
    if (_selectedCategory == 'All') return _menuItems;
    return _menuItems.where((e) => e.category == _selectedCategory).toList();
  }

  List<OrderItem> get _selectedOrderItems {
    final list = <OrderItem>[];
    for (final item in _menuItems) {
      final qty = _itemQuantities[item.id] ?? 0;
      if (qty > 0) {
        list.add(OrderItem(item: item, quantity: qty));
      }
    }
    return list;
  }

  int get _totalItemsCount =>
      _selectedOrderItems.fold(0, (sum, e) => sum + e.quantity);

  int get _orderTotal =>
      _selectedOrderItems.fold(0, (sum, e) => sum + e.total);

  bool get _isMixedSplitValid {
    if (_paymentType != PaymentType.mixed) return true;
    final cash = int.tryParse(_cashController.text) ?? 0;
    final upi = int.tryParse(_upiController.text) ?? 0;
    return cash > 0 && upi > 0 && (cash + upi == _orderTotal);
  }

  void _updateMixedAmounts(int total) {
    if (_paymentType != PaymentType.mixed) return;
    final half = total ~/ 2;
    _cashController.text = half.toString();
    _upiController.text = (total - half).toString();
  }

  @override
  void dispose() {
    _cashController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderTotal = _orderTotal;
    final totalCount = _totalItemsCount;
    final canProceed = totalCount > 0 && _isMixedSplitValid;
    final primary = AppTheme.primaryColor(context);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderColor(context),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  children: [
                    Text(
                      'Record Order',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    if (totalCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          '$totalCount',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (totalCount > 0)
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _itemQuantities.clear();
                            _cashController.clear();
                            _upiController.clear();
                          });
                        },
                        icon: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: AppTheme.textSecondary(context),
                        ),
                        label: Text(
                          'Reset',
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: AppTheme.textSecondary(context),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Divider(color: AppTheme.borderColor(context), height: 1),

              // Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Categories
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            final isSel = _selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: isSel,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() => _selectedCategory = cat);
                                }
                              },
                              selectedColor: primary.withValues(alpha: 0.20),
                              backgroundColor: AppTheme.cardColor(context),
                              side: BorderSide(
                                color: isSel ? primary : AppTheme.borderColor(context),
                              ),
                              labelStyle: TextStyle(
                                color: isSel ? primary : AppTheme.textSecondary(context),
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Products List
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select Products',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textSecondary(context),
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              foregroundColor: primary,
                            ),
                            onPressed: () async {
                              final security = context.read<SecurityProvider?>();
                              if (security != null && !security.canManageMenu) {
                                final ok = await PinDialog.prompt(
                                  context,
                                  title: 'Owner PIN Required',
                                  subtitle: 'Enter PIN to edit products or rates',
                                );
                                if (!ok || !context.mounted) return;
                              }
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const MenuManagementScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_note_rounded, size: 16),
                            label: const Text(
                              'Edit Rates / Add',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredItems.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final qty = _itemQuantities[item.id] ?? 0;
                          final isSelected = qty > 0;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primary.withValues(
                                      alpha: AppTheme.isDark(context) ? 0.12 : 0.08,
                                    )
                                  : AppTheme.cardColor(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? primary : AppTheme.borderColor(context),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                          fontSize: 14,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '₹${item.price}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (qty == 0)
                                  TextButton.icon(
                                    style: TextButton.styleFrom(
                                      backgroundColor: primary.withValues(alpha: 0.15),
                                      foregroundColor: primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _itemQuantities[item.id] = 1;
                                        _updateMixedAmounts(_orderTotal);
                                      });
                                    },
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text(
                                      'Add',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      IconButton.filled(
                                        style: IconButton.styleFrom(
                                          backgroundColor: AppTheme.cardElevatedColor(context),
                                          foregroundColor: AppTheme.textPrimary(context),
                                          minimumSize: const Size(34, 34),
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            side: BorderSide(color: AppTheme.borderColor(context)),
                                          ),
                                        ),
                                        icon: const Icon(Icons.remove, size: 16),
                                        onPressed: () {
                                          setState(() {
                                            if (qty <= 1) {
                                              _itemQuantities.remove(item.id);
                                            } else {
                                              _itemQuantities[item.id] = qty - 1;
                                            }
                                            _updateMixedAmounts(_orderTotal);
                                          });
                                        },
                                      ),
                                      Container(
                                        constraints: const BoxConstraints(minWidth: 34),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '$qty',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                            color: AppTheme.textPrimary(context),
                                          ),
                                        ),
                                      ),
                                      IconButton.filled(
                                        style: IconButton.styleFrom(
                                          backgroundColor: primary,
                                          foregroundColor: Colors.white,
                                          minimumSize: const Size(34, 34),
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: const Icon(Icons.add, size: 16),
                                        onPressed: () {
                                          if (qty < 99) {
                                            setState(() {
                                              _itemQuantities[item.id] = qty + 1;
                                              _updateMixedAmounts(_orderTotal);
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 18),

                      // 3. Current Order Summary (if any items)
                      if (_selectedOrderItems.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.cardElevatedColor(context),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderColor(context)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 18,
                                    color: primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Order Details ($totalCount items)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: primary,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '₹$orderTotal',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: primary,
                                    ),
                                  ),
                                ],
                              ),
                              Divider(color: AppTheme.borderColor(context), height: 16),
                              ..._selectedOrderItems.map(
                                (oi) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${oi.item.name} × ${oi.quantity}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary(context),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '₹${oi.total}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                      ],

                      // 4. Payment Method
                      Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary(context),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildPaymentChip(
                            context: context,
                            label: 'Cash',
                            type: PaymentType.cash,
                            color: AppTheme.cashGreen,
                            icon: Icons.payments_outlined,
                          ),
                          const SizedBox(width: 10),
                          _buildPaymentChip(
                            context: context,
                            label: 'UPI',
                            type: PaymentType.upi,
                            color: AppTheme.upiBlue,
                            icon: Icons.qr_code_2_rounded,
                          ),
                          const SizedBox(width: 10),
                          _buildPaymentChip(
                            context: context,
                            label: 'Mixed',
                            type: PaymentType.mixed,
                            color: AppTheme.mixedPurple,
                            icon: Icons.call_split_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 5. Mixed Payment Inputs
                      if (_paymentType == PaymentType.mixed) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.mixedPurple.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.mixedPurple.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Split Amount',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.mixedPurple,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Total: ₹$orderTotal',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppTheme.textSecondary(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _cashController,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary(context),
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Cash (₹)',
                                        isDense: true,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onChanged: (val) {
                                        final cash = int.tryParse(val) ?? 0;
                                        final upi = max(0, orderTotal - cash);
                                        _upiController.text = upi.toString();
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _upiController,
                                      keyboardType: TextInputType.number,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary(context),
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'UPI (₹)',
                                        isDense: true,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      onChanged: (val) {
                                        final upi = int.tryParse(val) ?? 0;
                                        final cash = max(0, orderTotal - upi);
                                        _cashController.text = cash.toString();
                                        setState(() {});
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              if (!_isMixedSplitValid && totalCount > 0) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  'Both amounts must be positive and add up to total.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.danger,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),

              // 6. Pinned Bottom Summary & Checkout Button
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor(context),
                  border: Border(
                    top: BorderSide(color: AppTheme.borderColor(context)),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Payable',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary(context),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (totalCount > 0)
                              Text(
                                '$totalCount items selected',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          '₹$orderTotal',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: canProceed ? AppTheme.dualGradient(context) : null,
                        color: canProceed ? null : primary.withValues(alpha: 0.3),
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.transparent,
                          disabledForegroundColor: Colors.white38,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: canProceed
                            ? () async {
                                final cashVal = _paymentType == PaymentType.cash
                                    ? orderTotal
                                    : (_paymentType == PaymentType.mixed
                                        ? (int.tryParse(_cashController.text) ?? 0)
                                        : 0);
                                final upiVal = _paymentType == PaymentType.upi
                                    ? orderTotal
                                    : (_paymentType == PaymentType.mixed
                                        ? (int.tryParse(_upiController.text) ?? 0)
                                        : 0);

                                final orderedSnapshot = List<OrderItem>.from(_selectedOrderItems);
                                final provider = context.read<SalesProvider>();
                                await provider.addOrder(
                                  items: orderedSnapshot,
                                  paymentType: _paymentType,
                                  cashAmount: cashVal,
                                  upiAmount: upiVal,
                                );

                                if (context.mounted) {
                                  Navigator.of(context).pop();

                                  final billReceipt = BillReceipt.fromOrder(
                                    orderItems: orderedSnapshot,
                                    paymentType: _paymentType,
                                    cashAmount: cashVal,
                                    upiAmount: upiVal,
                                    orderId: provider.sales.isNotEmpty ? provider.sales.first.id : null,
                                  );

                                  // Immediately show the consolidated digital bill sheet
                                  BillReceiptSheet.showReceipt(context, billReceipt);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: AppTheme.cardElevatedColor(context),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(color: AppTheme.cashGreen),
                                      ),
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: AppTheme.cashGreen),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Recorded $totalCount item(s) • ₹$orderTotal',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textPrimary(context),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      action: SnackBarAction(
                                        label: 'View Bill',
                                        textColor: AppTheme.primaryColor(context),
                                        onPressed: () {
                                          BillReceiptSheet.showReceipt(context, billReceipt);
                                        },
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                        icon: const Icon(Icons.check_circle_outline, size: 20),
                        label: Text(
                          totalCount == 0
                              ? 'Select Items'
                              : 'Proceed Sale ($totalCount items • ₹$orderTotal)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentChip({
    required BuildContext context,
    required String label,
    required PaymentType type,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _paymentType == type;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _paymentType = type;
            _updateMixedAmounts(_orderTotal);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: AppTheme.isDark(context) ? 0.16 : 0.10)
                : AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppTheme.borderColor(context),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? color : AppTheme.textSecondary(context),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? color : AppTheme.textPrimary(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
