import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/chat_store.dart';
import 'core/theme.dart';
import 'core/wallet_manager.dart';
import 'views/home_screen.dart';

void main() {
  runApp(const GlassChatApp());
}

class GlassChatApp extends StatelessWidget {
  const GlassChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<WalletManager>.value(value: WalletManager.I),
        ChangeNotifierProvider<ChatStore>.value(value: ChatStore.I),
      ],
      child: MaterialApp(
        title: 'GlassChat',
        debugShowCheckedModeBanner: false,
        theme: GlassTheme.dark(),
        home: const HomeScreen(),
      ),
    );
  }
}
