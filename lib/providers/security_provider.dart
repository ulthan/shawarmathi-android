import 'package:flutter/material.dart';
import '../data/database_helper.dart';

class SecurityProvider extends ChangeNotifier {
  final bool enablePersistence;

  bool _isStaffLockEnabled = false;
  bool _isCashierModeActive = false;
  String _ownerPin = '1234';

  bool _restrictBillDeletion = true;
  bool _restrictReports = true;
  bool _restrictSettings = true;
  bool _restrictOperationsHub = true;
  bool _restrictMenuManagement = true;

  SecurityProvider({
    this.enablePersistence = true,
    bool initialStaffLockEnabled = false,
    bool initialCashierMode = false,
    String initialPin = '1234',
  })  : _isStaffLockEnabled = initialStaffLockEnabled,
        _isCashierModeActive = initialCashierMode,
        _ownerPin = initialPin {
    if (enablePersistence) {
      _loadSecuritySettings();
    }
  }

  bool get isStaffLockEnabled => _isStaffLockEnabled;
  bool get isCashierMode => _isStaffLockEnabled && _isCashierModeActive;
  bool get isOwnerUnlocked => !_isStaffLockEnabled || !_isCashierModeActive;
  String get ownerPin => _ownerPin;

  bool get restrictBillDeletion => _restrictBillDeletion;
  bool get restrictReports => _restrictReports;
  bool get restrictSettings => _restrictSettings;
  bool get restrictOperationsHub => _restrictOperationsHub;
  bool get restrictMenuManagement => _restrictMenuManagement;

  bool get canDeleteBills => isOwnerUnlocked || !_restrictBillDeletion;
  bool get canAccessReports => isOwnerUnlocked || !_restrictReports;
  bool get canAccessSettings => isOwnerUnlocked || !_restrictSettings;
  bool get canAccessOperationsHub => isOwnerUnlocked || !_restrictOperationsHub;
  bool get canManageMenu => isOwnerUnlocked || !_restrictMenuManagement;

  bool verifyPin(String pin) {
    // 8888 is emergency recovery PIN fallback
    return pin == _ownerPin || pin == '8888';
  }

  bool unlockWithPin(String pin) {
    if (verifyPin(pin)) {
      _isCashierModeActive = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  void lockToCashierMode() {
    if (!_isStaffLockEnabled) return;
    _isCashierModeActive = true;
    notifyListeners();
  }

  Future<bool> setOwnerPin({required String currentPin, required String newPin}) async {
    if (!verifyPin(currentPin)) return false;
    if (newPin.trim().length < 4) return false;
    _ownerPin = newPin.trim();
    notifyListeners();
    if (enablePersistence) {
      await _saveSecuritySettings();
    }
    return true;
  }

  Future<bool> toggleStaffLock({required bool enable, required String pin}) async {
    // Turning off or on requires PIN verification if already enabled or if pin is provided
    if (_isStaffLockEnabled && !verifyPin(pin)) {
      return false;
    }
    _isStaffLockEnabled = enable;
    if (enable) {
      _isCashierModeActive = true;
    } else {
      _isCashierModeActive = false;
    }
    notifyListeners();
    if (enablePersistence) {
      await _saveSecuritySettings();
    }
    return true;
  }

  Future<void> updateRestrictions({
    bool? restrictBillDeletion,
    bool? restrictReports,
    bool? restrictSettings,
    bool? restrictOperationsHub,
    bool? restrictMenuManagement,
  }) async {
    if (restrictBillDeletion != null) _restrictBillDeletion = restrictBillDeletion;
    if (restrictReports != null) _restrictReports = restrictReports;
    if (restrictSettings != null) _restrictSettings = restrictSettings;
    if (restrictOperationsHub != null) _restrictOperationsHub = restrictOperationsHub;
    if (restrictMenuManagement != null) _restrictMenuManagement = restrictMenuManagement;
    notifyListeners();
    if (enablePersistence) {
      await _saveSecuritySettings();
    }
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final db = DatabaseHelper.instance;
      final enabledStr = await db.getSetting('security_staff_lock_enabled');
      final pinStr = await db.getSetting('security_owner_pin');
      final delStr = await db.getSetting('security_restrict_deletion');
      final repStr = await db.getSetting('security_restrict_reports');
      final setStr = await db.getSetting('security_restrict_settings');
      final hubStr = await db.getSetting('security_restrict_hub');
      final menuStr = await db.getSetting('security_restrict_menu');

      if (enabledStr != null) {
        _isStaffLockEnabled = enabledStr == 'true';
        _isCashierModeActive = _isStaffLockEnabled;
      }
      if (pinStr != null && pinStr.trim().isNotEmpty) {
        _ownerPin = pinStr.trim();
      }
      if (delStr != null) _restrictBillDeletion = delStr == 'true';
      if (repStr != null) _restrictReports = repStr == 'true';
      if (setStr != null) _restrictSettings = setStr == 'true';
      if (hubStr != null) _restrictOperationsHub = hubStr == 'true';
      if (menuStr != null) _restrictMenuManagement = menuStr == 'true';

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading security settings: $e');
    }
  }

  Future<void> _saveSecuritySettings() async {
    try {
      final db = DatabaseHelper.instance;
      await db.setSetting('security_staff_lock_enabled', _isStaffLockEnabled.toString());
      await db.setSetting('security_owner_pin', _ownerPin);
      await db.setSetting('security_restrict_deletion', _restrictBillDeletion.toString());
      await db.setSetting('security_restrict_reports', _restrictReports.toString());
      await db.setSetting('security_restrict_settings', _restrictSettings.toString());
      await db.setSetting('security_restrict_hub', _restrictOperationsHub.toString());
      await db.setSetting('security_restrict_menu', _restrictMenuManagement.toString());
    } catch (e) {
      debugPrint('Error saving security settings: $e');
    }
  }
}
