import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/chat_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/chat_list_screen.dart';

void main() {
  runApp(const GlassChatAndroidApp());
}

class GlassChatAndroidApp extends StatelessWidget {
  const GlassChatAndroidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ChatProvider>(create: (_) => ChatProvider()),
        ChangeNotifierProvider<SettingsProvider>(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'GlassChat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const ChatListScreen(),
      ),
    );
  }
}
