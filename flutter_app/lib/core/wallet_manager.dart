import 'package:flutter/foundation.dart';

/// Shared wallet state for the 2-in-1 ecosystem (@wallet and @fragment).
/// Mirrors the native Swift WalletManager: dual-currency balances, one-shot
/// KYC bonus, and username purchases. All observers rebuild on notify().
class WalletManager extends ChangeNotifier {
  WalletManager._();

  static final WalletManager I = WalletManager._();

  static const double kycBonus = 50000;

  double typ0kBalance = 500;
  double usdtBalance = 0.00;
  bool isKYCVerified = false;
  List<String> ownedUsernames = <String>['@alex'];

  // ---- Formatted output (fiat/token labels) ----

  String get netWorthLabel => '\$${(typ0kBalance + usdtBalance).toStringAsFixed(2)}';

  String get typ0kLabel => '${group(typ0kBalance)} \$TYP0K';

  String get usdtLabel => '\$${usdtBalance.toStringAsFixed(2)} USDT';

  static String group(double value) {
    final whole = value.truncate().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final remaining = whole.length - i;
      buffer.write(whole[i]);
      if (remaining > 1 && (remaining - 1) % 3 == 0) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  // ---- KYC ----

  /// Photo KYC: flips verification once and credits +50,000 $TYP0K.
  void verifyKYC() {
    if (isKYCVerified) return;
    isKYCVerified = true;
    typ0kBalance += kycBonus;
    notifyListeners();
  }

  // ---- Fragment purchases ----

  bool canAfford(double price) => typ0kBalance >= price;

  bool owns(String handle) => ownedUsernames.contains(handle);

  bool purchase({required String handle, required double price}) {
    if (owns(handle) || !canAfford(price)) return false;
    typ0kBalance -= price;
    ownedUsernames = <String>[...ownedUsernames, handle];
    notifyListeners();
    return true;
  }
}
