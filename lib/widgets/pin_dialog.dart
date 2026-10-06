import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/security_provider.dart';
import '../theme/app_theme.dart';

class PinDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool unlockOnSuccess;

  const PinDialog({
    super.key,
    this.title = 'Owner Authorization',
    this.subtitle = 'Enter 4-digit PIN to proceed',
    this.unlockOnSuccess = true,
  });

  static Future<bool> prompt(
    BuildContext context, {
    String title = 'Owner Authorization',
    String subtitle = 'Enter 4-digit PIN to proceed',
    bool unlockOnSuccess = true,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => PinDialog(
        title: title,
        subtitle: subtitle,
        unlockOnSuccess: unlockOnSuccess,
      ),
    );
    return result ?? false;
  }

  static Future<bool> showChangePin(BuildContext context) async {
    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          barrierColor: Colors.black54,
          builder: (ctx) => const _ChangePinFlowSheet(),
        ) ??
        false;
  }

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String? _errorMessage;
  bool _isSuccess = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onNumberPressed(String number) {
    if (_enteredPin.length >= 4 || _isSuccess) return;
    HapticFeedback.lightImpact();
    setState(() {
      _errorMessage = null;
      _enteredPin += number;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isEmpty || _isSuccess) return;
    HapticFeedback.selectionClick();
    setState(() {
      _errorMessage = null;
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    });
  }

  void _onClearPressed() {
    if (_enteredPin.isEmpty || _isSuccess) return;
    HapticFeedback.selectionClick();
    setState(() {
      _errorMessage = null;
      _enteredPin = '';
    });
  }

  void _verifyPin() {
    final security = context.read<SecurityProvider>();
    final isCorrect = security.verifyPin(_enteredPin);

    if (isCorrect) {
      HapticFeedback.mediumImpact();
      if (widget.unlockOnSuccess) {
        security.unlockWithPin(_enteredPin);
      }
      setState(() {
        _isSuccess = true;
      });
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      });
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
      setState(() {
        _errorMessage = 'Incorrect PIN. Try again.';
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final primary = AppTheme.primaryColor(context);

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final offset = _shakeAnimation.value;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppTheme.borderColor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.borderColor(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Icon Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: _isSuccess
                    ? const LinearGradient(
                        colors: [Color(0xFF06D6A0), Color(0xFF118AB2)],
                      )
                    : AppTheme.dualGradient(context),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isSuccess ? const Color(0xFF06D6A0) : primary)
                        .withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isSuccess ? Icons.lock_open_rounded : Icons.shield_rounded,
                size: 28,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 14),

            // Title
            Text(
              _isSuccess ? 'Authorization Approved' : widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: _isSuccess ? const Color(0xFF06D6A0) : AppTheme.textPrimary(context),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle
            Text(
              _isSuccess ? 'Access granted' : widget.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary(context),
              ),
            ),
            const SizedBox(height: 20),

            // PIN Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                Color dotColor;
                if (_isSuccess) {
                  dotColor = const Color(0xFF06D6A0);
                } else if (_errorMessage != null) {
                  dotColor = AppTheme.danger;
                } else if (isFilled) {
                  dotColor = primary;
                } else {
                  dotColor = isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.12);
                }

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: isFilled ? 18 : 14,
                  height: isFilled ? 18 : 14,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: isFilled
                        ? [
                            BoxShadow(
                              color: dotColor.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),

            // Error message display
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: _errorMessage != null ? 30 : 16,
              alignment: Alignment.center,
              child: _errorMessage != null
                  ? Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.danger,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Numeric Keypad
            Container(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: 10),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: 10),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Clear button
                      _buildKeypadButton(
                        onTap: _onClearPressed,
                        child: Text(
                          'CLEAR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ),
                      // 0 Button
                      _buildKeypadButton(
                        onTap: () => _onNumberPressed('0'),
                        child: Text(
                          '0',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                      ),
                      // Backspace Button
                      _buildKeypadButton(
                        onTap: _onBackspacePressed,
                        child: Icon(
                          Icons.backspace_outlined,
                          size: 20,
                          color: AppTheme.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Cancel action
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppTheme.textSecondary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) {
        return _buildKeypadButton(
          onTap: () => _onNumberPressed(d),
          child: Text(
            d,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary(context),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildKeypadButton({
    required VoidCallback onTap,
    required Widget child,
  }) {
    final isDark = AppTheme.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 72,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCardElevated : AppTheme.lightCardElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderColor(context)),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: child,
      ),
    );
  }
}

class _ChangePinFlowSheet extends StatefulWidget {
  const _ChangePinFlowSheet();

  @override
  State<_ChangePinFlowSheet> createState() => _ChangePinFlowSheetState();
}

class _ChangePinFlowSheetState extends State<_ChangePinFlowSheet> {
  int _step = 1; // 1: current pin, 2: new pin, 3: confirm new pin
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  String? _error;

  void _onDigit(String d) {
    setState(() {
      _error = null;
      if (_step == 1 && _currentPin.length < 4) {
        _currentPin += d;
        if (_currentPin.length == 4) _handleStep1();
      } else if (_step == 2 && _newPin.length < 4) {
        _newPin += d;
        if (_newPin.length == 4) {
          _step = 3;
        }
      } else if (_step == 3 && _confirmPin.length < 4) {
        _confirmPin += d;
        if (_confirmPin.length == 4) _handleStep3();
      }
    });
  }

  void _handleStep1() {
    final security = context.read<SecurityProvider>();
    if (security.verifyPin(_currentPin)) {
      setState(() {
        _step = 2;
        _error = null;
      });
    } else {
      setState(() {
        _error = 'Current PIN is incorrect';
        _currentPin = '';
      });
    }
  }

  Future<void> _handleStep3() async {
    if (_newPin == _confirmPin) {
      final security = context.read<SecurityProvider>();
      await security.setOwnerPin(currentPin: _currentPin, newPin: _newPin);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Owner PIN changed successfully! 🔐'),
            backgroundColor: Color(0xFF06D6A0),
          ),
        );
      }
    } else {
      setState(() {
        _error = 'New PINs do not match. Try again.';
        _step = 2;
        _newPin = '';
        _confirmPin = '';
      });
    }
  }

  void _backspace() {
    setState(() {
      _error = null;
      if (_step == 1 && _currentPin.isNotEmpty) {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      } else if (_step == 2 && _newPin.isNotEmpty) {
        _newPin = _newPin.substring(0, _newPin.length - 1);
      } else if (_step == 3 && _confirmPin.isNotEmpty) {
        _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final primary = AppTheme.primaryColor(context);

    String title;
    String subtitle;
    String currentBuffer;

    if (_step == 1) {
      title = 'Verify Current PIN';
      subtitle = 'Enter your current Owner PIN';
      currentBuffer = _currentPin;
    } else if (_step == 2) {
      title = 'Set New 4-Digit PIN';
      subtitle = 'Choose a secure PIN';
      currentBuffer = _newPin;
    } else {
      title = 'Confirm New PIN';
      subtitle = 'Re-enter the new 4-digit PIN';
      currentBuffer = _confirmPin;
    }

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderColor(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.dualGradient(context),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pin_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary(context),
            ),
          ),
          const SizedBox(height: 18),

          // Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFilled = index < currentBuffer.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: isFilled ? 16 : 12,
                height: isFilled ? 16 : 12,
                decoration: BoxDecoration(
                  color: isFilled ? primary : AppTheme.borderColor(context),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),

          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.danger,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 10),

          // Keypad
          Container(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              children: [
                _buildRow(['1', '2', '3']),
                const SizedBox(height: 8),
                _buildRow(['4', '5', '6']),
                const SizedBox(height: 8),
                _buildRow(['7', '8', '9']),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _btn('', () {}),
                    _btn('0', () => _onDigit('0')),
                    _btn('⌫', _backspace),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textSecondary(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> row) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: row.map((d) => _btn(d, () => _onDigit(d))).toList(),
    );
  }

  Widget _btn(String label, VoidCallback tap) {
    final isDark = AppTheme.isDark(context);
    return InkWell(
      onTap: label.isEmpty ? null : tap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 68,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: label.isEmpty
              ? Colors.transparent
              : (isDark ? AppTheme.darkCardElevated : AppTheme.lightCardElevated),
          borderRadius: BorderRadius.circular(16),
          border: label.isEmpty ? null : Border.all(color: AppTheme.borderColor(context)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary(context),
          ),
        ),
      ),
    );
  }
}
