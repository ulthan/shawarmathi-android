import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sales_provider.dart';
import '../providers/security_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/update_provider.dart';
import '../services/backup_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pin_dialog.dart';
import '../widgets/update_dialog.dart';
import 'menu_management_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider?>();
    final security = context.watch<SecurityProvider?>();
    final isDark = AppTheme.isDark(context);
    final primary = AppTheme.primaryColor(context);
    final secondary = AppTheme.secondaryColor(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Title
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary(context),
            letterSpacing: -0.5,
          ),
        ),
        Text(
          'Theme, preferences & app info',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary(context)),
        ),
        const SizedBox(height: 20),

        // SECTION: Appearance & Theme
        Row(
          children: [
            Icon(Icons.palette_outlined, size: 18, color: primary),
            const SizedBox(width: 8),
            Text(
              'APPEARANCE & THEME',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: primary,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // 1. Day / Night Mode Manual Control
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderColor(context)),
            boxShadow: AppTheme.cardShadow(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Display Mode',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose between Day mode, Night mode, or follow system settings',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 14),

              // 3 Mode Options
              if (themeProvider != null)
                Row(
                  children: ThemeModeOption.values.map((mode) {
                    final isSelected = themeProvider.themeModeOption == mode;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => themeProvider.setThemeMode(mode),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primary.withValues(alpha: isDark ? 0.22 : 0.12)
                                  : AppTheme.cardElevatedColor(context),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? primary
                                    : AppTheme.borderColor(context),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  mode.icon,
                                  size: 24,
                                  color: isSelected
                                      ? primary
                                      : AppTheme.textSecondary(context),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  mode.label.split(' ').first,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected
                                        ? primary
                                        : AppTheme.textPrimary(context),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Signature Theme (Saffron & Fire)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderColor(context)),
            boxShadow: AppTheme.cardShadow(context),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: AppTheme.dualGradient(context),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saffron & Fire',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Signature Arabian Shawarmathi Theme',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B35), // Fiery Charcoal Orange
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFB703), // Arabian Saffron Gold
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // SECTION: Staff PIN Lock & Cashier Mode
        if (security != null) ...[
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: primary),
              const SizedBox(width: 8),
              Text(
                'STAFF PIN LOCK & CASHIER MODE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: primary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Master Toggle Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: security.isStaffLockEnabled
                    ? primary.withValues(alpha: 0.4)
                    : AppTheme.borderColor(context),
              ),
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
                          Row(
                            children: [
                              Text(
                                'Staff PIN Lock',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                              if (security.isStaffLockEnabled) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: security.isCashierMode
                                        ? const Color(0xFFFF6B35).withValues(alpha: 0.18)
                                        : const Color(0xFF06D6A0).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    security.isCashierMode ? 'CASHIER LOCKED' : 'OWNER UNLOCKED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: security.isCashierMode
                                          ? const Color(0xFFFF6B35)
                                          : const Color(0xFF06D6A0),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Restrict cashier access to reports, settings, and deleting sales',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: security.isStaffLockEnabled,
                      activeThumbColor: primary,
                      onChanged: (enable) async {
                        if (enable) {
                          final ok = await PinDialog.prompt(
                            context,
                            title: 'Set / Confirm Owner PIN',
                            subtitle: 'Default PIN is 1234. Enter PIN to activate staff lock.',
                          );
                          if (ok) {
                            await security.toggleStaffLock(enable: true, pin: security.ownerPin);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Staff PIN Lock enabled! App set to Cashier Mode 🔒'),
                                  backgroundColor: Color(0xFFFF6B35),
                                ),
                              );
                            }
                          }
                        } else {
                          final ok = await PinDialog.prompt(
                            context,
                            title: 'Owner PIN Required',
                            subtitle: 'Enter PIN to disable staff lock',
                          );
                          if (ok) {
                            await security.toggleStaffLock(enable: false, pin: security.ownerPin);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Staff PIN Lock disabled. Full store access unlocked.'),
                                  backgroundColor: Color(0xFF06D6A0),
                                ),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                ),

                if (security.isStaffLockEnabled) ...[
                  const SizedBox(height: 16),
                  Divider(height: 1, color: AppTheme.borderColor(context)),
                  const SizedBox(height: 16),

                  // Quick Switch Mode Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Active Role',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          Text(
                            security.isCashierMode
                                ? 'Cashier mode active (Restricted)'
                                : 'Owner mode active (Full admin access)',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: security.isCashierMode
                              ? const Color(0xFF06D6A0)
                              : const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (security.isCashierMode) {
                            final ok = await PinDialog.prompt(
                              context,
                              title: 'Unlock Owner Mode',
                              subtitle: 'Enter 4-digit PIN to exit Cashier Mode',
                            );
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Switched to Owner Mode 👑'),
                                  backgroundColor: Color(0xFF06D6A0),
                                ),
                              );
                            }
                          } else {
                            security.lockToCashierMode();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Locked in Cashier Mode 🔒'),
                                backgroundColor: Color(0xFFFF6B35),
                              ),
                            );
                          }
                        },
                        icon: Icon(
                          security.isCashierMode ? Icons.lock_open_rounded : Icons.lock_rounded,
                          size: 16,
                        ),
                        label: Text(
                          security.isCashierMode ? 'Unlock Owner' : 'Lock Cashier',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Change PIN Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Owner Security PIN',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary(context),
                            ),
                          ),
                          Text(
                            'Default PIN: 1234',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary(context),
                            ),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primary,
                          side: BorderSide(color: primary.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => PinDialog.showChangePin(context),
                        icon: const Icon(Icons.key_rounded, size: 16),
                        label: const Text(
                          'Change PIN',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Granular Restrictions
                  Text(
                    'CASHIER RESTRICTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMuted(context),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Material(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            'Prevent Deleting Bills',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
                          ),
                          subtitle: Text(
                            'Cashiers must enter Owner PIN to delete any sales from history',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
                          ),
                          value: security.restrictBillDeletion,
                          activeThumbColor: primary,
                          onChanged: (v) => security.updateRestrictions(restrictBillDeletion: v),
                        ),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            'Lock Analytics & Reports',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
                          ),
                          subtitle: Text(
                            'Keep monthly total profit, revenue, and product charts private',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
                          ),
                          value: security.restrictReports,
                          activeThumbColor: primary,
                          onChanged: (v) => security.updateRestrictions(restrictReports: v),
                        ),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            'Lock App Settings & Backups',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
                          ),
                          subtitle: Text(
                            'Require PIN to access settings, database exports, and backups',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
                          ),
                          value: security.restrictSettings,
                          activeThumbColor: primary,
                          onChanged: (v) => security.updateRestrictions(restrictSettings: v),
                        ),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            'Lock Operations Hub',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
                          ),
                          subtitle: Text(
                            'Require PIN to access the store management hub',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
                          ),
                          value: security.restrictOperationsHub,
                          activeThumbColor: primary,
                          onChanged: (v) => security.updateRestrictions(restrictOperationsHub: v),
                        ),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          title: Text(
                            'Lock Product & Rate Changes',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary(context)),
                          ),
                          subtitle: Text(
                            'Require Owner PIN to modify menu items or change product prices',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
                          ),
                          value: security.restrictMenuManagement,
                          activeThumbColor: primary,
                          onChanged: (v) => security.updateRestrictions(restrictMenuManagement: v),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // SECTION: Store Info
        Row(
          children: [
            Icon(Icons.storefront_outlined, size: 18, color: secondary),
            const SizedBox(width: 8),
            Text(
              'STORE & APP INFO',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: secondary,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        _SettingItem(
          icon: Icons.info_outline,
          iconBg: primary.withValues(alpha: 0.15),
          iconColor: primary,
          title: 'App Version',
          subtitle: 'Shawarmathi v1.0 (Dynamic Dual-Color)',
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'v1.0',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        _SettingItem(
          icon: Icons.location_on_outlined,
          iconBg: Colors.teal.withValues(alpha: 0.15),
          iconColor: Colors.tealAccent,
          title: 'Store Address',
          subtitle: 'Room No. 4, Tagore Hall Building, Convent Road, Calicut',
        ),
        const SizedBox(height: 10),

        _SettingItem(
          icon: Icons.phone_outlined,
          iconBg: Colors.cyan.withValues(alpha: 0.15),
          iconColor: Colors.cyanAccent,
          title: 'Mobile',
          subtitle: '+91 9883 700 300',
        ),
        const SizedBox(height: 20),

        // SECTION: Data Backup & Safety
        Row(
          children: [
            Icon(Icons.shield_outlined, size: 18, color: secondary),
            const SizedBox(width: 8),
            Text(
              'DATA BACKUP & RECOVERY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: secondary,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Export Backup
        _SettingItem(
          icon: Icons.cloud_upload_outlined,
          iconBg: AppTheme.cashGreen.withValues(alpha: 0.15),
          iconColor: AppTheme.cashGreen,
          title: 'Export Sales Backup',
          subtitle: 'Save sales to file, Google Drive, or Bluetooth',
          trailing: FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.cashGreen.withValues(alpha: 0.15),
              foregroundColor: AppTheme.cashGreen,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => _handleExportBackup(context),
            child: const Text(
              'Export',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Restore Backup
        _SettingItem(
          icon: Icons.settings_backup_restore_rounded,
          iconBg: AppTheme.upiBlue.withValues(alpha: 0.15),
          iconColor: AppTheme.upiBlue,
          title: 'Restore Sales Backup',
          subtitle: 'Recover past sales from a .json backup file',
          trailing: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.upiBlue),
              foregroundColor: AppTheme.upiBlue,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => _handleRestoreBackup(context),
            child: const Text(
              'Restore',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 14),

        Divider(color: AppTheme.borderColor(context)),
        const SizedBox(height: 10),

        _SettingItem(
          icon: Icons.delete_forever_outlined,
          iconBg: AppTheme.danger.withValues(alpha: 0.15),
          iconColor: AppTheme.danger,
          title: 'Clear All Data',
          subtitle: 'Permanently delete all sales records',
          trailing: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.danger),
              foregroundColor: AppTheme.danger,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => _showClearAllDialog(context),
            child: const Text(
              'Clear',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // SECTION: Products & Menu
        Row(
          children: [
            Icon(Icons.restaurant_menu_rounded, size: 18, color: primary),
            const SizedBox(width: 8),
            Text(
              'PRODUCTS & MENU',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: primary,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        _SettingItem(
          icon: Icons.edit_note_rounded,
          iconBg: primary.withValues(alpha: 0.15),
          iconColor: primary,
          title: 'Manage Products & Rates',
          subtitle: 'Add new items, update prices & categories',
          trailing: FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: primary.withValues(alpha: 0.15),
              foregroundColor: primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (security != null && !security.canManageMenu) {
                final ok = await PinDialog.prompt(
                  context,
                  title: 'Owner PIN Required',
                  subtitle: 'Enter PIN to manage products and rates',
                );
                if (!ok || !context.mounted) return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MenuManagementScreen()),
              );
            },
            child: const Text(
              'Manage',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // SECTION: Software Updates & OTA
        Row(
          children: [
            Icon(Icons.system_update_rounded, size: 18, color: primary),
            const SizedBox(width: 8),
            Text(
              'SOFTWARE UPDATES & OTA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: primary,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Consumer<UpdateProvider>(
          builder: (context, updater, _) {
            final isChecking = updater.isChecking;
            final isAvailable = updater.isUpdateAvailable;
            final isUpToDate = updater.status == UpdateStatus.upToDate;

            String subtitleText;
            if (isChecking) {
              subtitleText = 'Checking GitHub releases online...';
            } else if (isAvailable && updater.updateInfo != null) {
              subtitleText = 'Update v${updater.updateInfo!.latestVersion} is ready to install!';
            } else if (isUpToDate) {
              subtitleText = 'App is up to date (Latest release)';
            } else if (updater.status == UpdateStatus.error) {
              subtitleText = 'Offline or unable to connect to GitHub';
            } else {
              subtitleText = 'Check online for newer releases and features';
            }

            return Column(
              children: [
                _SettingItem(
                  icon: Icons.system_update_alt_rounded,
                  iconBg: isAvailable
                      ? const Color(0xFFFF8C00).withValues(alpha: 0.2)
                      : primary.withValues(alpha: 0.15),
                  iconColor: isAvailable ? const Color(0xFFFF8C00) : primary,
                  title: 'Check for Updates',
                  subtitle: subtitleText,
                  trailing: isChecking
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: isAvailable
                                ? const Color(0xFFFF8C00)
                                : primary.withValues(alpha: 0.15),
                            foregroundColor: isAvailable ? Colors.white : primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            await updater.checkForUpdates(isManual: true);
                            if (!context.mounted) return;
                            if (updater.isUpdateAvailable && updater.updateInfo != null) {
                              UpdateDialog.show(context, updater.updateInfo!);
                            } else if (updater.status == UpdateStatus.upToDate) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Shawarmathi POS is up to date! ✨'),
                                  backgroundColor: Color(0xFF06D6A0),
                                ),
                              );
                            } else if (updater.status == UpdateStatus.error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(updater.errorMessage ?? 'Could not check for updates'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          },
                          child: Text(
                            isAvailable ? 'Update' : 'Check',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                _SettingItem(
                  icon: Icons.autorenew_rounded,
                  iconBg: Colors.blue.withValues(alpha: 0.15),
                  iconColor: Colors.lightBlueAccent,
                  title: 'Auto-Check on App Launch',
                  subtitle: 'Automatically check for updates when opening the app',
                  trailing: Switch(
                    value: updater.autoCheckOnStartup,
                    activeThumbColor: primary,
                    onChanged: (v) => updater.toggleAutoCheck(v),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),

        // Brand Banner Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor(context)),
            boxShadow: AppTheme.cardShadow(context),
          ),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/images/logo.jpg',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AppTheme.dualGradient(context),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: const Text('🥙', style: TextStyle(fontSize: 36)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ShaderMask(
                shaderCallback: (bounds) => AppTheme.dualGradient(context).createShader(bounds),
                child: const Text(
                  'Shawarmathi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                'The Real Arabian Taste',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Data stored securely offline on your device',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted(context)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Clear All Data',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary(context),
          ),
        ),
        content: Text(
          'This will permanently delete ALL sales records. This action cannot be undone.',
          style: TextStyle(color: AppTheme.textSecondary(context)),
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
            ),
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              await context.read<SalesProvider>().clearAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All sales data has been cleared.'),
                  ),
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExportBackup(BuildContext context) async {
    final sales = context.read<SalesProvider>().sales;
    if (sales.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sales records to export yet.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      await BackupService.exportBackup(sales);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  Future<void> _handleRestoreBackup(BuildContext context) async {
    try {
      final backup = await BackupService.pickAndParseBackup();
      if (backup == null || !context.mounted) return;

      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          backgroundColor: AppTheme.cardColor(context),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.settings_backup_restore_rounded, color: AppTheme.cashGreen),
              const SizedBox(width: 10),
              Text(
                'Restore Backup',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
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
                'Backup Summary:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              Text('• Records: ${backup.sales.length} sales',
                  style: TextStyle(color: AppTheme.textSecondary(context))),
              Text('• Total Value: ₹${backup.totalRevenue}',
                  style: TextStyle(color: AppTheme.textSecondary(context))),
              Text('• Exported: ${backup.exportedAt}',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted(context))),
              const SizedBox(height: 16),
              Text(
                'How would you like to restore?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text('Cancel', style: TextStyle(color: AppTheme.textMuted(context))),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.upiBlue),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final count = await context
                    .read<SalesProvider>()
                    .restoreSales(backup.sales, replace: false);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Merged $count new sales records from backup!'),
                      backgroundColor: AppTheme.cashGreen,
                    ),
                  );
                }
              },
              child: const Text('Merge'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor(context),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final count = await context
                    .read<SalesProvider>()
                    .restoreSales(backup.sales, replace: true);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Replaced with $count sales records from backup!'),
                      backgroundColor: AppTheme.cashGreen,
                    ),
                  );
                }
              },
              child: const Text('Replace All'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load backup: $e')),
        );
      }
    }
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
