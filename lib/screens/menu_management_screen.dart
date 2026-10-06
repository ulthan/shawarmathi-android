import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/menu_provider.dart';
import '../providers/security_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/pin_dialog.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _verifyOwnerPermission(BuildContext context) async {
    final security = context.read<SecurityProvider?>();
    if (security == null || security.canManageMenu) return true;

    final authorized = await PinDialog.prompt(
      context,
      title: 'Owner PIN Required',
      subtitle: 'Enter 4-digit PIN to modify products and rates',
    );
    return authorized;
  }

  void _showAddOrEditDialog(BuildContext context, {MenuItem? itemToEdit}) async {
    final hasPermission = await _verifyOwnerPermission(context);
    if (!hasPermission || !context.mounted) return;

    final isEditing = itemToEdit != null;
    final nameController =
        TextEditingController(text: isEditing ? itemToEdit.name : '');
    final priceController =
        TextEditingController(text: isEditing ? itemToEdit.price.toString() : '');
    final customCategoryController = TextEditingController();

    final menuProvider = context.read<MenuProvider>();
    final existingCategories = menuProvider.categories
        .where((c) => c != 'All' && c.trim().isNotEmpty)
        .toList();

    String currentCategory = isEditing
        ? itemToEdit.category
        : (existingCategories.isNotEmpty ? existingCategories.first : 'Sarook');

    final primary = AppTheme.primaryColor(context);
    final isDark = AppTheme.isDark(context);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isCustom = !existingCategories.contains(currentCategory);

            return Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 12,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.borderColor(context),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Product & Rate' : 'Add New Product',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: AppTheme.textSecondary(context)),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Product Name Field
                    Text(
                      'PRODUCT NAME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      autofocus: !isEditing,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary(context),
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. Shawarma Sarook Extra Cheese',
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondary(context).withValues(alpha: 0.6),
                        ),
                        prefixIcon: Icon(Icons.fastfood_outlined, color: primary, size: 20),
                        filled: true,
                        fillColor: isDark
                            ? AppTheme.darkCardElevated
                            : AppTheme.lightCardElevated,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderColor(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderColor(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Rate / Price Field
                    Text(
                      'RATE / PRICE (₹)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. 150',
                        hintStyle: TextStyle(
                          color: AppTheme.textSecondary(context).withValues(alpha: 0.6),
                        ),
                        prefixIcon: Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: primary,
                            ),
                          ),
                        ),
                        filled: true,
                        fillColor: isDark
                            ? AppTheme.darkCardElevated
                            : AppTheme.lightCardElevated,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderColor(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderColor(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primary, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Category Selector
                    Text(
                      'CATEGORY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: primary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...existingCategories.map((cat) {
                          final isSelected = currentCategory == cat && !isCustom;
                          return ChoiceChip(
                            label: Text(cat),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() {
                                  currentCategory = cat;
                                  customCategoryController.clear();
                                });
                              }
                            },
                            selectedColor: primary.withValues(alpha: 0.20),
                            backgroundColor: isDark
                                ? AppTheme.darkCardElevated
                                : AppTheme.lightCardElevated,
                            side: BorderSide(
                              color: isSelected ? primary : AppTheme.borderColor(context),
                              width: isSelected ? 1.5 : 1,
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? primary : AppTheme.textSecondary(context),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        }),
                        ChoiceChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCustom ? Icons.check : Icons.add,
                                size: 14,
                                color: isCustom ? primary : AppTheme.textSecondary(context),
                              ),
                              const SizedBox(width: 4),
                              const Text('Custom'),
                            ],
                          ),
                          selected: isCustom,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                currentCategory = 'Custom';
                              });
                            }
                          },
                          selectedColor: primary.withValues(alpha: 0.20),
                          backgroundColor: isDark
                              ? AppTheme.darkCardElevated
                              : AppTheme.lightCardElevated,
                          side: BorderSide(
                            color: isCustom ? primary : AppTheme.borderColor(context),
                            width: isCustom ? 1.5 : 1,
                          ),
                          labelStyle: TextStyle(
                            color: isCustom ? primary : AppTheme.textSecondary(context),
                            fontWeight: isCustom ? FontWeight.bold : FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    if (isCustom) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: customCategoryController,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(context),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter new category name',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondary(context).withValues(alpha: 0.6),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.darkCardElevated
                              : AppTheme.lightCardElevated,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppTheme.borderColor(context)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppTheme.borderColor(context)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: primary, width: 2),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppTheme.borderColor(context)),
                              foregroundColor: AppTheme.textSecondary(context),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () async {
                              final name = nameController.text.trim();
                              final priceText = priceController.text.trim();
                              final price = int.tryParse(priceText);

                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a product name'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              if (price == null || price <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please enter a valid rate greater than 0'),
                                    backgroundColor: Colors.redAccent,
                                  ),
                                );
                                return;
                              }

                              String finalCategory = currentCategory;
                              if (isCustom) {
                                final customText = customCategoryController.text.trim();
                                if (customText.isNotEmpty) {
                                  finalCategory = customText;
                                } else {
                                  finalCategory = 'General';
                                }
                              }

                              if (isEditing) {
                                final updatedItem = itemToEdit.copyWith(
                                  name: name,
                                  price: price,
                                  category: finalCategory,
                                );
                                await menuProvider.updateMenuItem(updatedItem);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Updated "$name" to ₹$price!'),
                                      backgroundColor: const Color(0xFF06D6A0),
                                    ),
                                  );
                                }
                              } else {
                                await menuProvider.addMenuItem(
                                  name: name,
                                  price: price,
                                  category: finalCategory,
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added "$name" (₹$price) to menu!'),
                                      backgroundColor: const Color(0xFF06D6A0),
                                    ),
                                  );
                                }
                              }

                              if (sheetContext.mounted) {
                                Navigator.of(sheetContext).pop();
                              }
                            },
                            child: Text(
                              isEditing ? 'Save Changes' : 'Add Product',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, MenuItem item) async {
    final hasPermission = await _verifyOwnerPermission(context);
    if (!hasPermission || !context.mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Product?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${item.name}" (₹${item.price}) from the menu?',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Past sales history will not be affected.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.bold),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<MenuProvider>().deleteMenuItem(item.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${item.name}" from menu'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showResetToDefaultsDialog(BuildContext context) async {
    final hasPermission = await _verifyOwnerPermission(context);
    if (!hasPermission || !context.mounted) return;

    final primary = AppTheme.primaryColor(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.restore_rounded, color: primary, size: 22),
            ),
            const SizedBox(width: 12),
            Text(
              'Reset to Defaults?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary(context),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will reset your menu back to the original 25 Shawarmathi items and standard rates.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Any custom products or price changes will be restored to default values.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary(context), fontWeight: FontWeight.bold),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Reset Menu', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<MenuProvider>().resetToDefaults();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu restored to default items and rates 🥙'),
            backgroundColor: Color(0xFF06D6A0),
          ),
        );
      }
    }
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('sarook')) return Icons.lunch_dining_rounded;
    if (cat.contains('arabi')) return Icons.restaurant_rounded;
    if (cat.contains('platter')) return Icons.dinner_dining_rounded;
    if (cat.contains('side') || cat.contains('frie')) return Icons.fastfood_rounded;
    if (cat.contains('juice')) return Icons.local_bar_rounded;
    if (cat.contains('drink') || cat.contains('water') || cat.contains('pepsi')) {
      return Icons.local_drink_rounded;
    }
    return Icons.restaurant_menu_rounded;
  }

  Color _getCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('sarook')) return const Color(0xFFFF5400);
    if (cat.contains('arabi')) return const Color(0xFFFFB703);
    if (cat.contains('platter')) return const Color(0xFFFB8500);
    if (cat.contains('side')) return const Color(0xFFE63946);
    if (cat.contains('juice')) return const Color(0xFF06D6A0);
    if (cat.contains('drink')) return const Color(0xFF118AB2);
    return const Color(0xFF8338EC);
  }

  @override
  Widget build(BuildContext context) {
    final menuProvider = context.watch<MenuProvider>();
    final allItems = menuProvider.items;
    final primary = AppTheme.primaryColor(context);
    final secondary = AppTheme.secondaryColor(context);
    final isDark = AppTheme.isDark(context);

    final filteredItems = allItems.where((item) {
      final matchesCategory =
          _selectedCategory == 'All' || item.category == _selectedCategory;
      final matchesQuery = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.category.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();

    final categories = menuProvider.categories;
    final totalProducts = allItems.length;
    final totalCategories = categories.where((c) => c != 'All').length;
    final minPrice = allItems.isEmpty
        ? 0
        : allItems.map((e) => e.price).reduce((a, b) => a < b ? a : b);
    final maxPrice = allItems.isEmpty
        ? 0
        : allItems.map((e) => e.price).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg(context),
      appBar: AppBar(
        title: Text(
          'Products & Rates',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary(context),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: AppTheme.surfaceColor(context),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Add Product',
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: primary,
            onPressed: () => _showAddOrEditDialog(context),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: AppTheme.textPrimary(context)),
            onSelected: (val) {
              if (val == 'reset') {
                _showResetToDefaultsDialog(context);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Reset to Default Menu'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditDialog(context),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          // 1. Overview Stats Banner
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Store Menu Catalog',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Edit selling rates & expand your menu',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.dualGradient(context),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.restaurant_menu_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Metrics Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.darkCardElevated
                        : AppTheme.lightCardElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn(
                        context,
                        label: 'Total Items',
                        value: '$totalProducts',
                        color: primary,
                      ),
                      Container(
                        width: 1,
                        height: 26,
                        color: AppTheme.borderColor(context),
                      ),
                      _buildStatColumn(
                        context,
                        label: 'Categories',
                        value: '$totalCategories',
                        color: secondary,
                      ),
                      Container(
                        width: 1,
                        height: 26,
                        color: AppTheme.borderColor(context),
                      ),
                      _buildStatColumn(
                        context,
                        label: 'Price Range',
                        value: '₹$minPrice - ₹$maxPrice',
                        color: const Color(0xFF06D6A0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Search Box
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim();
              });
            },
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimary(context),
            ),
            decoration: InputDecoration(
              hintText: 'Search product by name or category...',
              hintStyle: TextStyle(
                color: AppTheme.textSecondary(context).withValues(alpha: 0.6),
                fontSize: 13,
              ),
              prefixIcon: Icon(Icons.search_rounded, color: primary, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.cardColor(context),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppTheme.borderColor(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppTheme.borderColor(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 3. Category Filter Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
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
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // 4. Products Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PRODUCTS (${filteredItems.length})',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: primary,
                  letterSpacing: 1.0,
                ),
              ),
              if (_selectedCategory != 'All' || _searchQuery.isNotEmpty)
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedCategory = 'All';
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                  child: const Text('Show All', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // 5. Products List
          if (filteredItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.fastfood_outlined,
                    size: 48,
                    color: AppTheme.textSecondary(context).withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No products match your filter',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "+ Add Product" to create a new item',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showAddOrEditDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add New Product'),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = filteredItems[index];
                final catColor = _getCategoryColor(item.category);
                final catIcon = _getCategoryIcon(item.category);

                return Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor(context)),
                    boxShadow: AppTheme.cardShadow(context),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showAddOrEditDialog(context, itemToEdit: item),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            // Category Icon Badge
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: catColor.withValues(alpha: isDark ? 0.22 : 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: catColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Icon(catIcon, color: catColor, size: 20),
                            ),
                            const SizedBox(width: 12),

                            // Item Name & Category
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary(context),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      item.category,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: catColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Rate / Price Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: isDark ? 0.20 : 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: primary.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Text(
                                '₹${item.price}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            // Quick Edit Action
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppTheme.textSecondary(context),
                              ),
                              tooltip: 'Edit Rate / Details',
                              onPressed: () => _showAddOrEditDialog(context, itemToEdit: item),
                            ),

                            // Quick Delete Action
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: Colors.redAccent,
                              ),
                              tooltip: 'Delete Product',
                              onPressed: () => _showDeleteDialog(context, item),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
