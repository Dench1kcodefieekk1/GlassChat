import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/glass.dart';
import '../core/theme.dart';
import '../providers/chat_provider.dart';

/// Profile: avatar header with name + online status, account info card
/// (phone bound directly to the session user), and exactly three tab
/// segments: Media / Files / Links.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<ChatProvider>().me;
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
            const SizedBox(height: 22),
            UserAvatar(name: me.name, size: 92, isOnline: me.isOnline),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  me.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w600),
                ),
                if (me.isVerified)
                  const Padding(
                    padding: EdgeInsets.only(left: 6),
                    child: Icon(Icons.verified_rounded, color: AppTheme.accent),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              me.isOnline ? 'online' : me.lastSeenLabel,
              style: const TextStyle(color: AppTheme.online, fontSize: 13),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.phone_rounded,
                      tint: AppTheme.online,
                      title: me.phone,
                      subtitle: 'Phone',
                    ),
                    _InfoRow(
                      icon: Icons.alternate_email_rounded,
                      tint: Colors.orange,
                      title: '@${me.username}',
                      subtitle: 'Username',
                    ),
                    if (me.bio.isNotEmpty)
                      _InfoRow(
                        icon: Icons.info_outline_rounded,
                        tint: AppTheme.accent,
                        title: me.bio,
                        subtitle: 'Bio',
                      ),
                    _InfoRow(
                      icon: Icons.calendar_month_rounded,
                      tint: Colors.purple,
                      title: me.registrationLabel,
                      subtitle: 'Registration Date',
                    ),
                    _InfoRow(
                      icon: Icons.tag_rounded,
                      tint: Colors.white38,
                      title: me.userIdTag,
                      subtitle: 'User ID',
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

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String subtitle;

  const _InfoRow({
    required this.icon,
    required this.tint,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          dense: true,
          leading: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
          title: Text(title, style: const TextStyle(fontSize: 15)),
          subtitle: Text(subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.white38)),
        ),
        const Divider(height: 1, indent: 66),
      ],
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
          Icon(icon, size: 42, color: Colors.white24),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }
}
