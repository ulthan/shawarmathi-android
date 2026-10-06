import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/menu_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/security_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/update_provider.dart';
import 'screens/calendar_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/history_screen.dart';
import 'screens/operations_hub_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/add_sale_sheet.dart';
import 'widgets/pin_dialog.dart';
import 'widgets/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => SalesProvider()),
        ChangeNotifierProvider(create: (_) => SecurityProvider()),
        ChangeNotifierProvider(create: (_) => UpdateProvider()),
      ],
      child: const ShawarmathiApp(),
    ),
  );
}

class ShawarmathiApp extends StatelessWidget {
  final ThemeProvider? themeProvider;
  final SecurityProvider? securityProvider;
  final MenuProvider? menuProvider;
  final UpdateProvider? updateProvider;
  const ShawarmathiApp({
    super.key,
    this.themeProvider,
    this.securityProvider,
    this.menuProvider,
    this.updateProvider,
  });

  @override
  Widget build(BuildContext context) {
    ThemeProvider? tp = themeProvider;
    if (tp == null) {
      try {
        tp = Provider.of<ThemeProvider>(context);
      } catch (_) {
        tp = null;
      }
    }
    final activeTheme = tp ?? ThemeProvider(enablePersistence: false);

    SecurityProvider? sp = securityProvider;
    if (sp == null) {
      try {
        sp = Provider.of<SecurityProvider>(context);
      } catch (_) {
        sp = null;
      }
    }
    final activeSecurity = sp ?? SecurityProvider(enablePersistence: false);

    MenuProvider? mp = menuProvider;
    if (mp == null) {
      try {
        mp = Provider.of<MenuProvider>(context);
      } catch (_) {
        mp = null;
      }
    }

    UpdateProvider? up = updateProvider;
    if (up == null) {
      try {
        up = Provider.of<UpdateProvider>(context);
      } catch (_) {
        up = null;
      }
    }

    final isDark = activeTheme.themeModeOption == ThemeModeOption.night ||
        (activeTheme.themeModeOption == ThemeModeOption.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    Widget app = MaterialApp(
      title: 'Shawarmathi',
      debugShowCheckedModeBanner: false,
      theme: activeTheme.lightTheme,
      darkTheme: activeTheme.darkTheme,
      themeMode: activeTheme.materialThemeMode,
      home: const MainNavigationShell(),
    );

    try {
      Provider.of<SecurityProvider>(context, listen: false);
    } catch (_) {
      app = ChangeNotifierProvider<SecurityProvider>.value(
        value: activeSecurity,
        child: app,
      );
    }

    if (mp != null) {
      try {
        Provider.of<MenuProvider>(context, listen: false);
      } catch (_) {
        app = ChangeNotifierProvider<MenuProvider>.value(
          value: mp,
          child: app,
        );
      }
    }

    if (up != null) {
      try {
        Provider.of<UpdateProvider>(context, listen: false);
      } catch (_) {
        app = ChangeNotifierProvider<UpdateProvider>.value(
          value: up,
          child: app,
        );
      }
    }

    return app;
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoUpdate();
    });
  }

  void _checkAutoUpdate() {
    try {
      final updater = Provider.of<UpdateProvider?>(context, listen: false);
      if (updater != null && updater.autoCheckOnStartup) {
        updater.checkForUpdates().then((_) {
          if (mounted && updater.isUpdateAvailable && updater.updateInfo != null) {
            UpdateDialog.show(context, updater.updateInfo!);
          }
        }).catchError((_) {});
      }
    } catch (_) {}
  }

  Future<void> _navigateTo(int index) async {
    final security = context.read<SecurityProvider>();
    bool requiresAuth = false;
    String sectionName = '';

    if (index == 1 && !security.canAccessOperationsHub) {
      requiresAuth = true;
      sectionName = 'Operations Hub';
    } else if (index == 4 && !security.canAccessReports) {
      requiresAuth = true;
      sectionName = 'Analytics & Reports';
    } else if (index == 5 && !security.canAccessSettings) {
      requiresAuth = true;
      sectionName = 'Settings';
    }

    if (requiresAuth) {
      final authorized = await PinDialog.prompt(
        context,
        title: 'Owner PIN Required',
        subtitle: 'Enter 4-digit PIN to access $sectionName',
      );
      if (!authorized) return;
    }

    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  late final List<Widget> _screens = [
    DashboardScreen(onNavigate: _navigateTo),
    OperationsHubScreen(onNavigate: _navigateTo),
    const HistoryScreen(),
    const CalendarScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  static const List<String> _screenTitles = [
    'Shawarmathi',
    'Operations Hub',
    'Sales History',
    'Sales Calendar',
    'Analytics & Reports',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    ThemeProvider? themeProvider;
    try {
      themeProvider = Provider.of<ThemeProvider>(context);
    } catch (_) {
      themeProvider = null;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      drawer: _buildAppDrawer(context, isDark, primary, secondary),
      appBar: AppBar(
        leading: _currentIndex > 1
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
                onPressed: () {
                  setState(() {
                    _currentIndex = _previousIndex <= 1 ? _previousIndex : 0;
                  });
                },
              )
            : Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu_rounded),
                  tooltip: 'Menu',
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
        title: _currentIndex <= 1
            ? Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/logo.jpg',
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Text('🌯', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [primary, secondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      _currentIndex == 0 ? 'Shawarmathi' : 'Operations Hub',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              )
            : Text(
                _screenTitles[_currentIndex],
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppTheme.textPrimary(context),
                  letterSpacing: -0.3,
                ),
              ),
        actions: [
          // Staff PIN Lock / Cashier Mode Status Button
          Builder(
            builder: (ctx) {
              final security = ctx.watch<SecurityProvider>();
              if (!security.isStaffLockEnabled) return const SizedBox.shrink();

              if (security.isCashierMode) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () async {
                      final unlocked = await PinDialog.prompt(
                        ctx,
                        title: 'Unlock Owner Mode',
                        subtitle: 'Enter 4-digit PIN to exit Cashier Mode',
                      );
                      if (unlocked && ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Switched to Owner Mode 👑 (Full Access)'),
                            backgroundColor: Color(0xFF06D6A0),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF6B35).withValues(alpha: 0.6)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_rounded, size: 14, color: Color(0xFFFF6B35)),
                          SizedBox(width: 4),
                          Text(
                            'Cashier',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Tooltip(
                    message: 'Lock to Cashier Mode',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        security.lockToCashierMode();
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Locked in Cashier Mode 🔒'),
                            backgroundColor: Color(0xFFFF6B35),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06D6A0).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF06D6A0).withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded, size: 14, color: Color(0xFF06D6A0)),
                            SizedBox(width: 4),
                            Text(
                              'Owner',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF06D6A0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
          ),
          // Dynamic Day/Night Mode Switcher with smooth rotation
          if (themeProvider != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Tooltip(
                message: isDark ? 'Switch to Day Mode' : 'Switch to Night Mode',
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => themeProvider?.toggleDayNight(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkCard
                          : AppTheme.lightCardElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.borderColor(context),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return RotationTransition(
                          turns: animation,
                          child: ScaleTransition(scale: animation, child: child),
                        );
                      },
                      child: Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        key: ValueKey<bool>(isDark),
                        size: 20,
                        color: isDark ? const Color(0xFFFFB703) : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: PopScope(
        canPop: _currentIndex == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _currentIndex != 0) {
            setState(() {
              _currentIndex = _previousIndex <= 1 ? _previousIndex : 0;
            });
          }
        },
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: AppTheme.dualGradient(context),
          boxShadow: [
            BoxShadow(
              color: primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          highlightElevation: 0,
          onPressed: () => AddSaleSheet.show(context),
          icon: const Icon(Icons.add_circle, size: 22, color: Colors.white),
          label: const Text(
            'Add Sale',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
      bottomNavigationBar: _currentIndex > 1
          ? null
          : Builder(
              builder: (ctx) {
                final security = ctx.watch<SecurityProvider>();
                final isManageLocked = security.isCashierMode && !security.canAccessOperationsHub;
                return NavigationBar(
                  selectedIndex: _currentIndex,
                  onDestinationSelected: (idx) => _navigateTo(idx),
                  destinations: [
                    const NavigationDestination(
                      icon: Icon(Icons.space_dashboard_outlined),
                      selectedIcon: Icon(Icons.space_dashboard_rounded),
                      label: 'Dashboard',
                    ),
                    NavigationDestination(
                      icon: Icon(
                        isManageLocked
                            ? Icons.lock_outline_rounded
                            : Icons.grid_view_outlined,
                      ),
                      selectedIcon: const Icon(Icons.grid_view_rounded),
                      label: isManageLocked ? 'Manage 🔒' : 'Manage',
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildAppDrawer(
    BuildContext context,
    bool isDark,
    Color primary,
    Color secondary,
  ) {
    final themeProvider = Provider.of<ThemeProvider?>(context, listen: false);
    final security = Provider.of<SecurityProvider>(context);

    return Drawer(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderColor(context)),
                ),
                gradient: LinearGradient(
                  colors: [
                    primary.withValues(alpha: isDark ? 0.16 : 0.08),
                    secondary.withValues(alpha: isDark ? 0.08 : 0.03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            'assets/images/logo.jpg',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Text('🌯', style: TextStyle(fontSize: 28)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [primary, secondary],
                              ).createShader(bounds),
                              child: const Text(
                                'Shawarmathi',
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Professional Store POS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF06D6A0),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Store Online',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (security.isStaffLockEnabled)
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            Navigator.pop(context);
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: security.isCashierMode
                                  ? const Color(0xFFFF6B35).withValues(alpha: isDark ? 0.25 : 0.15)
                                  : const Color(0xFF06D6A0).withValues(alpha: isDark ? 0.25 : 0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: security.isCashierMode
                                    ? const Color(0xFFFF6B35).withValues(alpha: 0.5)
                                    : const Color(0xFF06D6A0).withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  security.isCashierMode ? Icons.lock_rounded : Icons.shield_rounded,
                                  size: 11,
                                  color: security.isCashierMode
                                      ? const Color(0xFFFF6B35)
                                      : const Color(0xFF06D6A0),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  security.isCashierMode ? 'Cashier Mode' : 'Owner Mode',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: security.isCashierMode
                                        ? const Color(0xFFFF6B35)
                                        : const Color(0xFF06D6A0),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Navigation List Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                children: [
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.space_dashboard_rounded,
                    title: 'Dashboard Overview',
                    subtitle: 'Real-time sales counter',
                    index: 0,
                    primary: primary,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.hub_rounded,
                    title: 'Operations Hub',
                    subtitle: 'Central store overview',
                    index: 1,
                    primary: primary,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    child: Divider(height: 1, color: AppTheme.borderColor(context)),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.receipt_long_rounded,
                    title: 'Sales History',
                    subtitle: 'Receipts & payment logs',
                    index: 2,
                    primary: primary,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.calendar_month_rounded,
                    title: 'Sales Calendar',
                    subtitle: 'Day-by-day & monthly ledger',
                    index: 3,
                    primary: primary,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.insights_rounded,
                    title: 'Analytics & Reports',
                    subtitle: 'Product charts & rush hours',
                    index: 4,
                    primary: primary,
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.tune_rounded,
                    title: 'App Settings & Preferences',
                    subtitle: 'Themes, day/night & backup',
                    index: 5,
                    primary: primary,
                  ),
                ],
              ),
            ),

            // Drawer Footer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.borderColor(context)),
                ),
              ),
              child: Column(
                children: [
                  if (themeProvider != null)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        themeProvider.toggleDayNight();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkCardElevated
                              : AppTheme.lightCardElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor(context)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                  size: 18,
                                  color: isDark ? const Color(0xFFFFB703) : primary,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  isDark ? 'Switch to Day Mode' : 'Switch to Night Mode',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary(context),
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.sync_rounded,
                              size: 15,
                              color: AppTheme.textSecondary(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Shawarmathi POS v2.0 • Pro Edition',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required int index,
    required Color primary,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = AppTheme.isDark(context);
    final security = context.watch<SecurityProvider>();

    bool isItemLocked = false;
    if (security.isCashierMode) {
      if (index == 1 && !security.canAccessOperationsHub) isItemLocked = true;
      if (index == 4 && !security.canAccessReports) isItemLocked = true;
      if (index == 5 && !security.canAccessSettings) isItemLocked = true;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? primary.withValues(alpha: isDark ? 0.22 : 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(
            icon,
            color: isSelected ? primary : AppTheme.textSecondary(context),
            size: 21,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? primary : AppTheme.textPrimary(context),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondary(context),
            ),
          ),
          trailing: isSelected
              ? Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                )
              : (isItemLocked
                  ? const Icon(
                      Icons.lock_rounded,
                      size: 14,
                      color: Color(0xFFFF6B35),
                    )
                  : null),
          onTap: () {
            Navigator.pop(context);
            _navigateTo(index);
          },
        ),
      ),
    );
  }
}
