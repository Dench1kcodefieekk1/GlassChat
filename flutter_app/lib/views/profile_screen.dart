import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/chat_store.dart';
import '../widgets/glass.dart';

/// Profile: avatar, name + verified badge, dynamically bound phone
/// (currentUser.phone — no static fallbacks), and Media / Files / Links tabs.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<ChatStore>().me;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('My Profile'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Media'),
              Tab(text: 'Files'),
              Tab(text: 'Links'),
            ],
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 46,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.3),
              child: Text(
                me.name.isNotEmpty ? me.name[0] : '?',
                style: const TextStyle(
                    fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(me.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600)),
                if (me.isVerified)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.verified_rounded,
                        color: Color(0xFF3D9BFF)),
                  ),
              ],
            ),
            Text('@${me.username}',
                style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.alternate_email_rounded,
                          color: Colors.orange),
                      title: Text('@${me.username}'),
                      subtitle: const Text('Username'),
                    ),
                    ListTile(
                      leading:
                          const Icon(Icons.phone_rounded, color: Colors.green),
                      title: Text(me.phone),
                      subtitle: const Text('Phone'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.calendar_month_rounded,
                          color: Colors.purple),
                      title: const Text('October 2026'),
                      subtitle: const Text('Registration Date'),
                    ),
                  ],
                ),
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _EmptyTab(label: 'No media yet', icon: Icons.photo_rounded),
                  _EmptyTab(label: 'No files yet', icon: Icons.folder_rounded),
                  _EmptyTab(label: 'No links yet', icon: Icons.link_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTab extends StatelessWidget {
  final String label;
  final IconData icon;

  const _EmptyTab({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: Colors.white24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }
}
