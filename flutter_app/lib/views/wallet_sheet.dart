import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/wallet_manager.dart';
import '../widgets/glass.dart';
import 'kyc_sheet.dart';

/// Opens the @wallet mini app as a draggable glass bottom sheet.
void showWalletSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const WalletMiniAppSheet(),
  );
}

/// Wallet mini app: USD net-worth header, $TYP0K / USDT rows, quick actions,
/// and the interactive photo-KYC bonus banner. Watches WalletManager so the
/// +50,000 $TYP0K bonus updates every number instantly.
class WalletMiniAppSheet extends StatefulWidget {
  const WalletMiniAppSheet({super.key});

  @override
  State<WalletMiniAppSheet> createState() => _WalletMiniAppSheetState();
}

class _WalletMiniAppSheetState extends State<WalletMiniAppSheet> {
  void _onVerified() {
    // Give the user a beat to see 50,500 land, then dismiss both sheets.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletManager>();
    final height = MediaQuery.of(context).size.height;

    return Container(
      height: height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF10151F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Wallet',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close_rounded, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _NetWorthCard(wallet: wallet),
              const SizedBox(height: 12),
              if (!wallet.isKYCVerified) ...[
                _KycBanner(onStart: () => showKycSheet(context, onVerified: _onVerified)),
                const SizedBox(height: 12),
              ],
              _BalancesCard(wallet: wallet),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NetWorthCard extends StatelessWidget {
  final WalletManager wallet;

  const _NetWorthCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A54C4), Color(0xFF4A2F9E)],
        ),
      ),
      child: Column(
        children: [
          const Text('Estimated Net Worth',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              wallet.netWorthLabel,
              key: ValueKey<String>(wallet.netWorthLabel),
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickAction(icon: Icons.download_rounded, label: 'Deposit'),
              _QuickAction(icon: Icons.upload_rounded, label: 'Send'),
              _QuickAction(
                  icon: Icons.swap_horiz_rounded, label: 'Exchange'),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;

  const _QuickAction({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 5),
        Text(label,
            style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }
}

class _KycBanner extends StatelessWidget {
  final VoidCallback onStart;

  const _KycBanner({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFFFB833), Color(0xFFFF6B47)],
        ),
      ),
      child: Column(
        children: [
          const Text(
            '🎉 Пройдите верификацию по фото и получите +50,000 \$TYP0K!',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            onPressed: onStart,
            child: const Text('Пройти KYC'),
          ),
        ],
      ),
    );
  }
}

class _BalancesCard extends StatelessWidget {
  final WalletManager wallet;

  const _BalancesCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: const TokenIcon(
              text: 'T',
              colors: [Color(0xFF2A54C4), Color(0xFF5C33CC)],
            ),
            title: const Text('\$TYP0K Token'),
            trailing: Text(
              wallet.typ0kLabel,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const Divider(height: 1, indent: 62),
          ListTile(
            leading: const TokenIcon(
              text: '₮',
              colors: [Color(0xFF119E86)],
            ),
            title: const Text('Tether USDT'),
            trailing: Text(
              wallet.usdtLabel,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
