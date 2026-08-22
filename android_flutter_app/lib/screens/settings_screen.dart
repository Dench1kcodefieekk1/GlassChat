import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/glass.dart';
import '../core/theme.dart';
import '../providers/settings_provider.dart';

/// Settings hub: Notifications, Privacy, Appearance, Account.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        children: const [
          _SettingsCard(entries: [
            _Entry(
              icon: Icons.notifications_rounded,
              tint: Color(0xFFFF453A),
              title: 'Notifications',
              destination: _NotificationsPage(),
            ),
            _Entry(
              icon: Icons.privacy_tip_outlined,
              tint: Color(0xFF32D3C6),
              title: 'Privacy',
              destination: _PrivacyPage(),
            ),
          ]),
          SizedBox(height: 12),
          _SettingsCard(entries: [
            _Entry(
              icon: Icons.palette_outlined,
              tint: Color(0xFFBF5AF2),
              title: 'Appearance',
              destination: _AppearancePage(),
            ),
            _Entry(
              icon: Icons.person_outline_rounded,
              tint: AppTheme.accent,
              title: 'Account',
              destination: _AccountPage(),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Entry {
  final IconData icon;
  final Color tint;
  final String title;
  final Widget destination;

  const _Entry({
    required this.icon,
    required this.tint,
    required this.title,
    required this.destination,
  });
}

class _SettingsCard extends StatelessWidget {
  final List<_Entry> entries;

  const _SettingsCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            ListTile(
              leading: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: entries[index].tint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(entries[index].icon,
                    size: 17, color: Colors.white),
              ),
              title: Text(entries[index].title,
                  style: const TextStyle(fontSize: 15)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white38),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => entries[index].destination,
              )),
            ),
            if (index < entries.length - 1)
              const Divider(height: 1, indent: 66),
          ],
        ],
      ),
    );
  }
}

class _SettingsDetailPage extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const _SettingsDetailPage({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        children: rows,
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final bool value;
  final VoidCallback onChanged;

  const _ToggleRow({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        dense: true,
        title: Text(title, style: const TextStyle(fontSize: 15)),
        value: value,
        onChanged: (_) => onChanged(),
      ),
    );
  }
}

class _NotificationsPage extends StatelessWidget {
  const _NotificationsPage();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return _SettingsDetailPage(
      title: 'Notifications and Sounds',
      rows: [
        _ToggleRow(
          title: 'Message notifications',
          value: settings.notifyMessages,
          onChanged: settings.toggleNotifyMessages,
        ),
        const SizedBox(height: 8),
        _ToggleRow(
          title: 'Sounds',
          value: settings.notifySounds,
          onChanged: settings.toggleNotifySounds,
        ),
        const SizedBox(height: 8),
        _ToggleRow(
          title: 'Message previews',
          value: settings.notifyPreviews,
          onChanged: settings.toggleNotifyPreviews,
        ),
      ],
    );
  }
}

class _PrivacyPage extends StatelessWidget {
  const _PrivacyPage();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return _SettingsDetailPage(
      title: 'Privacy',
      rows: [
        _ToggleRow(
          title: 'Show last seen',
          value: settings.showLastSeen,
          onChanged: settings.toggleShowLastSeen,
        ),
        const SizedBox(height: 8),
        _ToggleRow(
          title: 'Read receipts',
          value: settings.readReceipts,
          onChanged: settings.toggleReadReceipts,
        ),
        const SizedBox(height: 8),
        _ToggleRow(
          title: 'Allow calls',
          value: settings.allowCalls,
          onChanged: settings.toggleAllowCalls,
        ),
      ],
    );
  }
}

class _AppearancePage extends StatelessWidget {
  const _AppearancePage();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return _SettingsDetailPage(
      title: 'Appearance',
      rows: [
        _ToggleRow(
          title: 'Dark mode',
          value: settings.darkMode,
          onChanged: settings.toggleDarkMode,
        ),
        const SizedBox(height: 8),
        _ToggleRow(
          title: 'Rounded bubbles',
          value: settings.bubblesRounded,
          onChanged: settings.toggleBubblesRounded,
        ),
      ],
    );
  }
}

class _AccountPage extends StatelessWidget {
  const _AccountPage();

  @override
  Widget build(BuildContext context) {
    return _SettingsDetailPage(
      title: 'Account',
      rows: [
        GlassCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.lock_outline_rounded,
                color: Colors.white38),
            title: const Text('Passcode lock', style: TextStyle(fontSize: 15)),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: Colors.white38),
            onTap: () {},
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(Icons.devices_rounded, color: Colors.white38),
            title: const Text('Active sessions', style: TextStyle(fontSize: 15)),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: Colors.white38),
            onTap: () {},
          ),
        ),
      ],
    );
  }
}
