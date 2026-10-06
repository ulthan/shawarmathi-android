import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/menu_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/security_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/pin_dialog.dart';
import 'menu_management_screen.dart';

class OperationsHubScreen extends StatelessWidget {
  final void Function(int index)? onNavigate;

  const OperationsHubScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final salesProvider = context.watch<SalesProvider>();
    final sales = salesProvider.sales;
    final primary = AppTheme.primaryColor(context);
    final secondary = AppTheme.secondaryColor(context);
    final isDark = AppTheme.isDark(context);

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final todaySales = sales.where((s) => s.dateKey == todayStr).toList();
    final todayRev = todaySales.fold<int>(0, (sum, s) => sum + s.total);
    final todayQty = todaySales.fold<int>(0, (sum, s) => sum + s.quantity);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.borderColor(context)),
            boxShadow: AppTheme.cardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Operations & Insights',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary(context),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dedicated management hub for your store',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
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
                    child: const Icon(Icons.hub_rounded, color: Colors.white, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Today's Pulse Summary
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
                    _buildPulseStat(
                      context,
                      label: "Today's Revenue",
                      value: '₹$todayRev',
                      color: primary,
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: AppTheme.borderColor(context),
                    ),
                    _buildPulseStat(
                      context,
                      label: "Shawarmas Sold",
                      value: '$todayQty',
                      color: secondary,
                    ),
                    Container(
                      width: 1,
                      height: 28,
                      color: AppTheme.borderColor(context),
                    ),
                    _buildPulseStat(
                      context,
                      label: "Total Orders",
                      value: '${sales.length}',
                      color: const Color(0xFF06D6A0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section Title
        Row(
          children: [
            Icon(Icons.apps_rounded, size: 18, color: primary),
            const SizedBox(width: 8),
            Text(
              'MANAGEMENT MODULES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: primary,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 2x2 Grid of Management Modules
        Row(
          children: [
            Expanded(
              child: _buildGridHubCard(
                context: context,
                icon: Icons.receipt_long_rounded,
                iconGradient: [const Color(0xFFFFB703), const Color(0xFFFB8500)],
                title: 'Sales History',
                subtitle: 'Ledger & receipts',
                badgeText: '${sales.length} orders',
                onTap: () => onNavigate?.call(2),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildGridHubCard(
                context: context,
                icon: Icons.calendar_month_rounded,
                iconGradient: [const Color(0xFF06D6A0), const Color(0xFF118AB2)],
                title: 'Sales Calendar',
                subtitle: 'Heatmap & ledger',
                badgeText: 'Monthly view',
                onTap: () => onNavigate?.call(3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildGridHubCard(
                context: context,
                icon: Icons.insights_rounded,
                iconGradient: [const Color(0xFF3A86FF), const Color(0xFF8338EC)],
                title: 'Analytics & Reports',
                subtitle: 'Charts & rush hours',
                badgeText: 'Insights',
                onTap: () => onNavigate?.call(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildGridHubCard(
                context: context,
                icon: Icons.tune_rounded,
                iconGradient: [const Color(0xFFFF006E), const Color(0xFF8338EC)],
                title: 'Settings & Preferences',
                subtitle: 'Themes & shop',
                badgeText: 'Config',
                onTap: () => onNavigate?.call(5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Products & Menu Rates Featured Card
        _buildFeaturedHubCard(
          context: context,
          icon: Icons.restaurant_menu_rounded,
          iconGradient: [const Color(0xFFFF5400), const Color(0xFFFF9E00)],
          title: 'Products & Rates',
          subtitle: 'Add new items, update rates & manage menu',
          badgeText: '${context.watch<MenuProvider?>()?.items.length ?? 25} items',
          onTap: () async {
            SecurityProvider? security;
            try {
              security = context.read<SecurityProvider?>();
            } catch (_) {}
            if (security != null && !security.canManageMenu) {
              final ok = await PinDialog.prompt(
                context,
                title: 'Owner PIN Required',
                subtitle: 'Enter 4-digit PIN to access Products & Rates',
              );
              if (!ok || !context.mounted) return;
            }
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MenuManagementScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeaturedHubCard({
    required BuildContext context,
    required IconData icon,
    required List<Color> iconGradient,
    required String title,
    required String subtitle,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    final isDark = AppTheme.isDark(context);

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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: iconGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: iconGradient.first.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? iconGradient.first.withValues(alpha: 0.18)
                                  : iconGradient.first.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: iconGradient.first,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: AppTheme.textSecondary(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulseStat(
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
            fontSize: 15,
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

  Widget _buildGridHubCard({
    required BuildContext context,
    required IconData icon,
    required List<Color> iconGradient,
    required String title,
    required String subtitle,
    required String badgeText,
    required VoidCallback onTap,
  }) {
    final isDark = AppTheme.isDark(context);

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
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: iconGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: iconGradient.first.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? iconGradient.first.withValues(alpha: 0.18)
                            : iconGradient.first.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: iconGradient.first,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
