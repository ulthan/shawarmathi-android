import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shawarmathi/main.dart';
import 'package:shawarmathi/models/app_update_info.dart';
import 'package:shawarmathi/models/sale_entity.dart';
import 'package:shawarmathi/providers/menu_provider.dart';
import 'package:shawarmathi/providers/sales_provider.dart';
import 'package:shawarmathi/providers/security_provider.dart';
import 'package:shawarmathi/providers/theme_provider.dart';
import 'package:shawarmathi/providers/update_provider.dart';
import 'package:shawarmathi/data/menu_repository.dart';
import 'package:shawarmathi/data/sales_repository.dart';
import 'package:shawarmathi/screens/history_screen.dart';
import 'package:shawarmathi/screens/menu_management_screen.dart';
import 'package:shawarmathi/services/app_update_service.dart';
import 'package:shawarmathi/theme/app_theme.dart';
import 'package:shawarmathi/widgets/add_sale_sheet.dart';
import 'package:shawarmathi/widgets/bill_receipt_sheet.dart';
import 'package:shawarmathi/widgets/update_dialog.dart';

class MockSalesRepository implements SalesRepository {
  final List<SaleEntity> _mockSales = [];

  @override
  Future<List<SaleEntity>> getAllSales() async => List.unmodifiable(_mockSales);

  @override
  Future<List<SaleEntity>> getSalesByDate(String dateKey) async =>
      _mockSales.where((s) => s.dateKey == dateKey).toList();

  @override
  Future<List<SaleEntity>> getSalesSince(String startDate) async =>
      _mockSales.where((s) => s.dateKey.compareTo(startDate) >= 0).toList();

  @override
  Future<int> addSale(SaleEntity sale) async {
    _mockSales.add(sale);
    return _mockSales.length;
  }

  @override
  Future<void> insertBatch(List<SaleEntity> sales) async {
    _mockSales.addAll(sales);
  }

  @override
  Future<void> deleteSale(int id) async {
    _mockSales.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> clearAll() async {
    _mockSales.clear();
  }
}

void main() {
  testWidgets('ShawarmathiApp smoke test', (WidgetTester tester) async {
    final mockRepo = MockSalesRepository();
    final salesProvider = SalesProvider(repository: mockRepo);
    final themeProvider = ThemeProvider(enablePersistence: false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<SalesProvider>.value(value: salesProvider),
        ],
        child: const ShawarmathiApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Shawarmathi'), findsWidgets);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('This Month'), findsOneWidget);
    expect(find.text('Shawarmas Sold'), findsOneWidget);
    expect(find.text('Total Revenue'), findsOneWidget);
    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('UPI'), findsOneWidget);
    expect(find.text('Mixed (Cash + UPI)'), findsOneWidget);
    expect(find.text('Recent Sales', skipOffstage: false), findsOneWidget);
    expect(find.text('Add Sale'), findsOneWidget);
  });

  testWidgets('Manual Day and Night mode toggle test', (WidgetTester tester) async {
    final mockRepo = MockSalesRepository();
    final salesProvider = SalesProvider(repository: mockRepo);
    final themeProvider = ThemeProvider(enablePersistence: false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<SalesProvider>.value(value: salesProvider),
        ],
        child: const ShawarmathiApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Default is Night Mode
    expect(themeProvider.isNight, isTrue);
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);

    // Tap day/night toggle in AppBar
    await tester.tap(find.byIcon(Icons.light_mode_rounded));
    await tester.pumpAndSettle();

    // Now in Day Mode
    expect(themeProvider.isDay, isTrue);
    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);

    // Tap back to Night Mode
    await tester.tap(find.byIcon(Icons.dark_mode_rounded));
    await tester.pumpAndSettle();

    expect(themeProvider.isNight, isTrue);
  });

  testWidgets('Manage view modules and Settings signature Saffron & Fire theme', (WidgetTester tester) async {
    final mockRepo = MockSalesRepository();
    final salesProvider = SalesProvider(repository: mockRepo);
    final themeProvider = ThemeProvider(enablePersistence: false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<SalesProvider>.value(value: salesProvider),
        ],
        child: const ShawarmathiApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Navigate to Manage tab
    await tester.tap(find.text('Manage'));
    await tester.pumpAndSettle();

    // Verify Quick Actions panel is removed
    expect(find.text('QUICK ACTIONS'), findsNothing);
    expect(find.text('Record New Sale'), findsNothing);

    // Verify Management Modules exist
    expect(find.text('Sales History'), findsOneWidget);
    expect(find.text('Sales Calendar'), findsOneWidget);
    expect(find.text('Analytics & Reports'), findsOneWidget);
    expect(find.text('Settings & Preferences'), findsOneWidget);

    // Tap Settings & Preferences
    await tester.tap(find.text('Settings & Preferences'));
    await tester.pumpAndSettle();

    // Verify signature Saffron & Fire theme and Theme modes
    expect(find.text('Saffron & Fire'), findsOneWidget);
    expect(find.text('Signature Arabian Shawarmathi Theme'), findsOneWidget);
    expect(find.text('Day'), findsOneWidget);
    expect(find.text('Night'), findsOneWidget);

    // Tap Day mode in Settings
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();

    expect(themeProvider.isDay, isTrue);
    expect(themeProvider.dualPalette, DualPaletteType.saffronFire);

    // Scroll down in Settings
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    // Verify Backup & Restore section in Settings
    expect(find.text('DATA BACKUP & RECOVERY'), findsOneWidget);
    expect(find.text('Export Sales Backup'), findsOneWidget);
    expect(find.text('Restore Sales Backup'), findsOneWidget);
  });

  testWidgets('Digital Bill / Receipt sheet displays consolidated multi-item bill and share options',
      (WidgetTester tester) async {
    const sale1 = SaleEntity(
      id: 101,
      timestamp: 1775380000000,
      dateKey: '2026-10-05',
      itemId: 1,
      itemName: 'Chicken Shawarma Normal',
      itemPrice: 100,
      quantity: 2,
      total: 200,
      paymentType: 'UPI',
      upiAmount: 340,
    );
    const sale2 = SaleEntity(
      id: 102,
      timestamp: 1775380000000,
      dateKey: '2026-10-05',
      itemId: 2,
      itemName: 'Chicken Shawarma Spicy',
      itemPrice: 140,
      quantity: 1,
      total: 140,
      paymentType: 'UPI',
      upiAmount: 340,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.buildDarkTheme(DualPaletteType.saffronFire),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => BillReceiptSheet.showSales(context, [sale1, sale2]),
              child: const Text('Open Bill'),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Bill'));
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsWidgets);
    expect(find.text('Bill #101'), findsOneWidget);
    expect(find.text('1. Chicken Shawarma Normal'), findsOneWidget);
    expect(find.text('2 × ₹100'), findsOneWidget);
    expect(find.text('2. Chicken Shawarma Spicy'), findsOneWidget);
    expect(find.text('1 × ₹140'), findsOneWidget);
    expect(find.text('Total Items'), findsOneWidget);
    expect(find.text('2 items (3 rolls)'), findsOneWidget);
    expect(find.text('TOTAL BILL'), findsOneWidget);
    expect(find.text('₹340'), findsOneWidget);
    expect(find.text('Paid via UPI'), findsOneWidget);
    expect(find.text('Share PDF Bill (Bluetooth / Print)'), findsOneWidget);
    expect(find.text('Share Text'), findsOneWidget);
    expect(find.text('Copy'), findsOneWidget);
  });

  testWidgets('Sales History groups items into a single bill card when billed together',
      (WidgetTester tester) async {
    final mockRepo = MockSalesRepository();
    // 3 items with identical timestamp from one order
    await mockRepo.addSale(
      const SaleEntity(
        id: 1,
        timestamp: 1775380000000,
        dateKey: '2026-10-05',
        itemId: 1,
        itemName: 'Shawarma Sarook Full Meat',
        itemPrice: 180,
        quantity: 1,
        total: 180,
        paymentType: 'CASH',
        cashAmount: 560,
      ),
    );
    await mockRepo.addSale(
      const SaleEntity(
        id: 2,
        timestamp: 1775380000000,
        dateKey: '2026-10-05',
        itemId: 2,
        itemName: 'Shawarma Sarook Chicken',
        itemPrice: 200,
        quantity: 1,
        total: 200,
        paymentType: 'CASH',
        cashAmount: 560,
      ),
    );
    await mockRepo.addSale(
      const SaleEntity(
        id: 3,
        timestamp: 1775380000000,
        dateKey: '2026-10-05',
        itemId: 3,
        itemName: 'Shawarma Arabi',
        itemPrice: 180,
        quantity: 1,
        total: 180,
        paymentType: 'CASH',
        cashAmount: 560,
      ),
    );

    final salesProvider = SalesProvider(repository: mockRepo);
    await salesProvider.loadSales();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SalesProvider>.value(value: salesProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.buildDarkTheme(DualPaletteType.saffronFire),
          home: const Scaffold(
            body: HistoryScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('1 bill found'), findsOneWidget);
    expect(find.text('₹560'), findsWidgets);
    expect(find.text('Shawarma Sarook Full Meat'), findsOneWidget);
    expect(find.text('Shawarma Sarook Chicken'), findsOneWidget);
    expect(find.text('Shawarma Arabi'), findsOneWidget);
    expect(find.text('3 item(s) • 3 roll(s)'), findsOneWidget);
  });

  testWidgets('Staff PIN Lock & Cashier Mode protects restricted sections and prompts for PIN', (WidgetTester tester) async {
    final mockRepo = MockSalesRepository();
    final salesProvider = SalesProvider(repository: mockRepo);
    final themeProvider = ThemeProvider(enablePersistence: false);
    final securityProvider = SecurityProvider(
      enablePersistence: false,
      initialStaffLockEnabled: true,
      initialCashierMode: true,
      initialPin: '1234',
    );

    // Verify initial provider state
    expect(securityProvider.isStaffLockEnabled, isTrue);
    expect(securityProvider.isCashierMode, isTrue);
    expect(securityProvider.canAccessOperationsHub, isFalse);
    expect(securityProvider.canAccessReports, isFalse);
    expect(securityProvider.canAccessSettings, isFalse);
    expect(securityProvider.canDeleteBills, isFalse);

    // Verify PIN verification logic
    expect(securityProvider.verifyPin('1234'), isTrue);
    expect(securityProvider.verifyPin('8888'), isTrue); // Master override
    expect(securityProvider.verifyPin('0000'), isFalse);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<SalesProvider>.value(value: salesProvider),
          ChangeNotifierProvider<SecurityProvider>.value(value: securityProvider),
        ],
        child: const ShawarmathiApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Cashier badge is visible in AppBar
    expect(find.text('Cashier'), findsOneWidget);

    // Tap on Manage tab (Operations Hub is restricted in Cashier mode)
    await tester.tap(find.text('Manage 🔒'));
    await tester.pumpAndSettle();

    // Verify Owner PIN Required dialog opened
    expect(find.text('Owner PIN Required'), findsOneWidget);
    expect(find.text('Enter 4-digit PIN to access Operations Hub'), findsOneWidget);
    expect(find.text('CLEAR'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    // Dismiss by tapping Cancel
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Verify still on Dashboard (not navigated to Operations Hub)
    expect(find.text('Owner PIN Required'), findsNothing);
    expect(find.text('Today'), findsOneWidget);

    // Unlock via PIN directly in security provider
    final unlocked = securityProvider.unlockWithPin('1234');
    expect(unlocked, isTrue);
    expect(securityProvider.isCashierMode, isFalse);
    expect(securityProvider.canAccessOperationsHub, isTrue);

    await tester.pumpAndSettle();

    // After unlocking, AppBar shows Owner badge instead of Cashier
    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
  });

  test('MenuProvider allows adding new products and updating existing product rates', () async {
    final inMemoryRepo = InMemoryMenuRepository();
    final menuProvider = MenuProvider(repository: inMemoryRepo);
    await menuProvider.loadMenuItems();

    expect(menuProvider.items.length, 25);
    expect(menuProvider.categories.contains('Sarook'), isTrue);

    // 1. Update existing rate
    final sarook = menuProvider.items.firstWhere((e) => e.name == 'Shawarma Sarook');
    expect(sarook.price, 120);
    await menuProvider.updateRate(id: sarook.id, newPrice: 125);

    final updatedSarook = menuProvider.items.firstWhere((e) => e.name == 'Shawarma Sarook');
    expect(updatedSarook.price, 125);

    // 2. Add new product with custom rate and category
    final created = await menuProvider.addMenuItem(
      name: 'Shawarma Sarook Special Jumbo',
      price: 250,
      category: 'Sarook Specials',
    );

    expect(created.id, isNonZero);
    expect(created.name, 'Shawarma Sarook Special Jumbo');
    expect(created.price, 250);
    expect(menuProvider.items.length, 26);
    expect(menuProvider.categories.contains('Sarook Specials'), isTrue);

    // 3. Delete product
    await menuProvider.deleteMenuItem(created.id);
    expect(menuProvider.items.length, 25);
    expect(menuProvider.items.any((e) => e.id == created.id), isFalse);

    // 4. Reset to defaults
    await menuProvider.resetToDefaults();
    final resetSarook = menuProvider.items.firstWhere((e) => e.name == 'Shawarma Sarook');
    expect(resetSarook.price, 120);
  });

  testWidgets('MenuManagementScreen displays catalog, allows searching and adding products',
      (WidgetTester tester) async {
    final inMemoryRepo = InMemoryMenuRepository();
    final menuProvider = MenuProvider(repository: inMemoryRepo);
    await menuProvider.loadMenuItems();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MenuProvider>.value(value: menuProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.buildDarkTheme(DualPaletteType.saffronFire),
          home: const MenuManagementScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header & stats banner
    expect(find.text('Products & Rates'), findsOneWidget);
    expect(find.text('Store Menu Catalog'), findsOneWidget);
    expect(find.text('25'), findsOneWidget); // 25 total items
    expect(find.text('Shawarma Sarook'), findsOneWidget);
    expect(find.text('₹120'), findsWidgets);

    // Search for drinks
    await tester.enterText(find.byType(TextField).first, 'Pepsi');
    await tester.pumpAndSettle();

    expect(find.widgetWithText(InkWell, 'Pepsi'), findsOneWidget);
    expect(find.text('Shawarma Sarook'), findsNothing);

    // Clear search
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(find.text('Shawarma Sarook'), findsOneWidget);

    // Tap Floating Action Button "Add Product"
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('Add New Product'), findsOneWidget);
    expect(find.text('PRODUCT NAME'), findsOneWidget);
    expect(find.text('RATE / PRICE (₹)'), findsOneWidget);

    // Enter new product details
    final textFields = find.descendant(
      of: find.byType(SingleChildScrollView),
      matching: find.byType(TextField),
    );

    // Enter name
    await tester.enterText(textFields.at(0), 'Falafel Roll');
    // Enter rate
    await tester.enterText(textFields.at(1), '90');

    // Tap Save button
    await tester.tap(find.widgetWithText(FilledButton, 'Add Product'));
    await tester.pumpAndSettle();

    // Verify product was added
    expect(menuProvider.items.any((e) => e.name == 'Falafel Roll' && e.price == 90), isTrue);
    expect(find.text('Falafel Roll'), findsOneWidget);
  });

  testWidgets('AddSaleSheet reflects dynamic menu rates and offers Edit Rates option',
      (WidgetTester tester) async {
    final inMemoryRepo = InMemoryMenuRepository();
    final menuProvider = MenuProvider(repository: inMemoryRepo);
    await menuProvider.loadMenuItems();

    // Update Shawarma Sarook rate to 135
    final sarook = menuProvider.items.firstWhere((e) => e.name == 'Shawarma Sarook');
    await menuProvider.updateRate(id: sarook.id, newPrice: 135);

    final mockRepo = MockSalesRepository();
    final salesProvider = SalesProvider(repository: mockRepo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MenuProvider>.value(value: menuProvider),
          ChangeNotifierProvider<SalesProvider>.value(value: salesProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.buildDarkTheme(DualPaletteType.saffronFire),
          home: const Scaffold(
            body: AddSaleSheet(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify updated price is shown in AddSaleSheet
    expect(find.text('Shawarma Sarook'), findsOneWidget);
    expect(find.text('₹135'), findsOneWidget);

    // Verify "Edit Rates / Add" button exists
    expect(find.text('Edit Rates / Add'), findsOneWidget);
  });

  test('UpdateProvider detects newer release and tracks download lifecycle', () async {
    final fakeService = FakeAppUpdateService(
      nextUpdateInfo: const AppUpdateInfo(
        latestVersion: '1.1.0',
        latestBuildNumber: 2,
        currentVersion: '1.0.0',
        currentBuildNumber: 1,
        releaseTitle: 'Shawarmathi v1.1.0 Major Update',
        releaseNotes: '- In-app product management\n- Updated rates',
        apkDownloadUrl: 'https://github.com/ulthan/shawarmathi-android/releases/download/v1.1.0/app-release.apk',
        apkFileName: 'app-release.apk',
        apkSizeBytes: 60000000,
        htmlUrl: 'https://github.com/ulthan/shawarmathi-android/releases/tag/v1.1.0',
      ),
    );

    final provider = UpdateProvider(updateService: fakeService);
    expect(provider.status, UpdateStatus.idle);
    expect(provider.isUpdateAvailable, isFalse);

    await provider.checkForUpdates();
    expect(provider.status, UpdateStatus.available);
    expect(provider.isUpdateAvailable, isTrue);
    expect(provider.updateInfo?.latestVersion, '1.1.0');
    expect(provider.updateInfo?.formattedSize, '57.2 MB');

    await provider.startDownloadAndInstall();
    expect(provider.status, UpdateStatus.downloaded);
    expect(provider.progress, 1.0);
    expect(provider.receivedBytes, 60000000);
  });

  testWidgets('UpdateDialog renders version pills, release notes, and install trigger', (WidgetTester tester) async {
    const info = AppUpdateInfo(
      latestVersion: '1.1.0',
      latestBuildNumber: 2,
      currentVersion: '1.0.0',
      currentBuildNumber: 1,
      releaseTitle: 'Shawarmathi v1.1.0',
      releaseNotes: 'Fixed rates and new auto-updater',
      apkDownloadUrl: 'https://github.com/ulthan/shawarmathi-android/releases/download/v1.1.0/app-release.apk',
      apkFileName: 'app-release.apk',
      apkSizeBytes: 60000000,
      htmlUrl: 'https://github.com/ulthan/shawarmathi-android/releases/tag/v1.1.0',
    );

    final fakeService = FakeAppUpdateService(nextUpdateInfo: info);
    final updateProvider = UpdateProvider(updateService: fakeService);
    await updateProvider.checkForUpdates();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UpdateProvider>.value(value: updateProvider),
        ],
        child: MaterialApp(
          theme: AppTheme.buildDarkTheme(DualPaletteType.saffronFire),
          home: const Scaffold(
            body: UpdateDialog(updateInfo: info),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('App Update Available'), findsOneWidget);
    expect(find.text('v1.0.0'), findsOneWidget);
    expect(find.text('v1.1.0'), findsOneWidget);
    expect(find.text('Fixed rates and new auto-updater'), findsOneWidget);
    expect(find.text('Download & Install'), findsOneWidget);
    expect(find.text('Open Browser'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);

    // Download and verify completed state
    await updateProvider.startDownloadAndInstall();
    await tester.pump();
    expect(find.text('Install Now'), findsOneWidget);
  });
}


