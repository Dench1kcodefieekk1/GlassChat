import SwiftUI

/// `@fragment` mini app: collectible username auction house. Purchases draw
/// from the shared wallet — the +50,000 $TYP0K KYC bonus unlocks the
/// expensive handles — and post a receipt back to the Fragment chat.
struct FragmentMiniAppView: View {
    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    private let wallet = WalletManager.shared
    @State private var notice: String?

    // MARK: Listings

    struct Listing: Identifiable {
        enum Status: String {
            case auction = "AUCTION"
            case buyNow = "BUY NOW"

            var color: Color {
                self == .buyNow ? Color(red: 0.07, green: 0.62, blue: 0.52) : Color(red: 0.85, green: 0.45, blue: 0.05)
            }
        }

        let id = UUID()
        let handle: String
        let price: Double
        let status: Status
    }

    private let listings: [Listing] = [
        Listing(handle: "@vip", price: 500, status: .buyNow),
        Listing(handle: "@boss", price: 10_000, status: .buyNow),
        Listing(handle: "@dark", price: 25_000, status: .auction),
        Listing(handle: "@cyber", price: 40_000, status: .buyNow),
        Listing(handle: "@star", price: 8_000, status: .auction),
        Listing(handle: "@wolf", price: 45_000, status: .auction)
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(spacing: 14) {
                    heroBanner

                    if let notice {
                        Text(notice)
                            .font(.footnote.weight(.medium))
                            .foregroundStyle(.red)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(listings) { listing in
                            ListingCell(listing: listing) {
                                buy(listing)
                            }
                        }
                    }
                }
                .padding(14)
            }
        }
        .background(Color.black.opacity(0.9).ignoresSafeArea())
        .presentationDetents([.large])
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.body)
                .foregroundStyle(.blue)

            Text("Fragment")
                .font(.headline)

            Spacer()

            Text("💎 \(wallet.typ0kBalance.formatted(.number.grouping(.automatic))) $TYP0K")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .contentTransition(.numericText())
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.white.opacity(0.1), in: Capsule())
                .foregroundStyle(.white)

            Button {
                Haptics.light()
                notice = nil
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Reload")

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
            }
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.black.opacity(0.55))
    }

    // MARK: - Hero

    private var heroBanner: some View {
        VStack(spacing: 6) {
            Text("Fragment")
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
            Text("Trade Unique Collectible Usernames")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Purchase

    private func buy(_ listing: Listing) {
        Haptics.medium()

        guard wallet.canAfford(listing.price) else {
            notice = "Недостаточно $TYP0K — пройдите KYC в кошельке, чтобы получить бонус."
            return
        }

        guard wallet.purchase(handle: listing.handle, price: listing.price) else {
            notice = "Юзернейм уже принадлежит вам."
            return
        }

        // Bind the new handle to the active profile.
        let cleanName = String(listing.handle.dropFirst())
        var user = store.currentUser
        user.username = cleanName
        store.users[user.id] = user
        store.save()

        let priceLabel = listing.price.formatted(.number.grouping(.automatic))
        store.postSystemMessage(
            chatID: "chat-fragment",
            senderID: User.fragmentBotID,
            text: "🎉 Успешно! Юзернейм \(listing.handle) выкуплен и привязан к вашему профилю. Списано: \(priceLabel) $TYP0K."
        )
        Haptics.success()
        dismiss()
    }
}

// MARK: - Listing cell

private struct ListingCell: View {
    let listing: FragmentMiniAppView.Listing
    let onBuy: () -> Void

    private var isOwned: Bool {
        WalletManager.shared.owns(listing.handle)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(listing.handle)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(listing.price.formatted(.number.grouping(.automatic)) + " $TYP0K")
                .font(.caption2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.75))

            Text(isOwned ? "YOURS" : listing.status.rawValue)
                .font(.system(size: 9, weight: .bold))
                .monospaced()
                .foregroundStyle(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    isOwned ? AnyShapeStyle(Color.blue) : AnyShapeStyle(listing.status.color),
                    in: Capsule()
                )

            Button(action: onBuy) {
                Text("Купить за \(listing.price.formatted(.number.grouping(.automatic)))")
                    .font(.system(size: 10, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(
                        isOwned ? AnyShapeStyle(Color.white.opacity(0.25)) : AnyShapeStyle(Color.white),
                        in: Capsule()
                    )
            }
            .disabled(isOwned)
        }
        .padding(10)
        .frame(height: 128)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.white.opacity(0.14), lineWidth: 1)
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
