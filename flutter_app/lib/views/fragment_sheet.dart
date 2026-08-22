import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/chat_store.dart';
import '../core/wallet_manager.dart';
import '../widgets/glass.dart';

/// Opens the @fragment mini app as a full-height dark glass sheet.
void showFragmentSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const FragmentMiniAppSheet(),
  );
}

class _Listing {
  final String handle;
  final double price;
  final bool auction;

  const _Listing(this.handle, this.price, {this.auction = false});
}

/// Fragment username auction market: verified header with the live $TYP0K
/// balance, glass hero, and a lazy 3-column grid of collectible handles.
class FragmentMiniAppSheet extends StatelessWidget {
  const FragmentMiniAppSheet({super.key});

  static const List<_Listing> _listings = [
    _Listing('@vip', 500),
    _Listing('@boss', 10000),
    _Listing('@dark', 25000, auction: true),
    _Listing('@cyber', 40000),
    _Listing('@star', 8000, auction: true),
    _Listing('@wolf', 45000, auction: true),
  ];

  void _buy(BuildContext context, _Listing listing) {
    final wallet = WalletManager.I;
    final store = ChatStore.I;
    HapticFeedback.mediumImpact();

    if (!wallet.canAfford(listing.price)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Недостаточно \$TYP0K — пройдите KYC в кошельке, чтобы получить бонус.'),
        ),
      );
      return;
    }
    if (!wallet.purchase(handle: listing.handle, price: listing.price)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Юзернейм уже принадлежит вам.')),
      );
      return;
    }

    store.setUsername(listing.handle.replaceFirst('@', ''));
    store.postMessage(
      chatId: ChatStore.fragmentChatId,
      senderId: ChatStore.fragmentBotId,
      text:
          '🎉 Успешно! Юзернейм ${listing.handle} выкуплен и привязан к вашему профилю. Списано: ${WalletManager.group(listing.price)} \$TYP0K.',
    );
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletManager>();
    final height = MediaQuery.of(context).size.height;

    return Container(
      height: height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFF080B12),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      color: Color(0xFF3D9BFF), size: 20),
                  const SizedBox(width: 6),
                  const Text('Fragment',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius:
                          const BorderRadius.all(Radius.circular(20)),
                    ),
                    child: Text(
                      '💎 ${WalletManager.group(wallet.typ0kBalance)} \$TYP0K',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.refresh_rounded, size: 20),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Column(
                  children: [
                    const Text('Fragment',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Trade Unique Collectible Usernames',
                        style: TextStyle(
                            fontSize: 12, color: Colors.white.withOpacity(0.6))),
                  ],
                ),
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(14),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.72,
                ),
                itemCount: _listings.length,
                itemBuilder: (context, index) {
                  final listing = _listings[index];
                  final owned = wallet.owns(listing.handle);
                  return _ListingCell(
                    listing: listing,
                    owned: owned,
                    onBuy: () => _buy(context, listing),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingCell extends StatelessWidget {
  final _Listing listing;
  final bool owned;
  final VoidCallback onBuy;

  const _ListingCell({
    required this.listing,
    required this.owned,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(10),
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            listing.handle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '${WalletManager.group(listing.price)} \$TYP0K',
            style: const TextStyle(fontSize: 10, color: Colors.white54),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: owned
                  ? const Color(0xFF3D9BFF)
                  : listing.auction
                      ? const Color(0xFFD9730D)
                      : const Color(0xFF119E86),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: Text(
              owned ? 'YOURS' : (listing.auction ? 'AUCTION' : 'BUY NOW'),
              style: const TextStyle(
                  fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: owned ? null : onBuy,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
              decoration: BoxDecoration(
                color: owned ? Colors.white.withOpacity(0.15) : Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(14)),
              ),
              child: Text(
                'Купить за ${WalletManager.group(listing.price)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.black,
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
