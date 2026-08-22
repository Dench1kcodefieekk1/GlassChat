import 'package:flutter/foundation.dart';

/// Settings state for the preferences screens.
class SettingsProvider extends ChangeNotifier {
  // Notifications
  bool notifyMessages = true;
  bool notifySounds = true;
  bool notifyPreviews = true;

  // Privacy
  bool showLastSeen = true;
  bool readReceipts = true;
  bool allowCalls = true;

  // Appearance
  bool darkMode = true;
  bool bubblesRounded = true;

  void toggleNotifyMessages() {
    notifyMessages = !notifyMessages;
    notifyListeners();
  }

  void toggleNotifySounds() {
    notifySounds = !notifySounds;
    notifyListeners();
  }

  void toggleNotifyPreviews() {
    notifyPreviews = !notifyPreviews;
    notifyListeners();
  }

  void toggleShowLastSeen() {
    showLastSeen = !showLastSeen;
    notifyListeners();
  }

  void toggleReadReceipts() {
    readReceipts = !readReceipts;
    notifyListeners();
  }

  void toggleAllowCalls() {
    allowCalls = !allowCalls;
    notifyListeners();
  }

  void toggleDarkMode() {
    darkMode = !darkMode;
    notifyListeners();
  }

  void toggleBubblesRounded() {
    bubblesRounded = !bubblesRounded;
    notifyListeners();
  }
}
