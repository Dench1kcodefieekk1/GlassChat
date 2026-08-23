import SwiftUI

/// `@wallet` mini app: net-worth header, dual-currency balances, quick
/// actions, and the photo-KYC bonus banner. Observes `WalletManager` so the
/// KYC bonus updates every number the moment it lands.
struct WalletMiniAppView: View {
    @Environment(\.dismiss) private var dismiss
    private let wallet = WalletManager.shared
    @State private var showKYC = false
    @State private var toast: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    kycBanner
                    balancesCard
                }
                .padding(16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Wallet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showKYC) {
                KYCVerificationSheet(onVerified: {
                    showKYC = false
                    showToast("Баланс обновлен: \(wallet.typ0kBalanceLabel)")
                })
            }
            .overlay(alignment: .bottom) {
                if let toast {
                    Text(toast)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassEffect(.regular, in: Capsule())
                        .padding(.bottom, 16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: toast)
        }
        .presentationDetents([.large])
    }

    // MARK: - Header

    private var headerCard: some View {
        VStack(spacing: 12) {
            Text("Estimated Net Worth")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.75))
            Text(wallet.netWorthLabel)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            HStack(spacing: 10) {
                quickAction("Deposit", "arrow.down.circle.fill") { showToast("Пополнение скоро появится") }
                quickAction("Send", "arrow.up.circle.fill") { showToast("Отправка скоро появится") }
                quickAction("Exchange", "arrow.left.arrow.right.circle.fill") { showToast("Обмен скоро появится") }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            LinearGradient(colors: [Color(red: 0.16, green: 0.32, blue: 0.72), Color(red: 0.28, green: 0.18, blue: 0.62)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }

    private func quickAction(_ title: String, _ symbol: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            action()
        } label: {
            VStack(spacing: 5) {
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .medium))
                Text(title)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - KYC banner

    @ViewBuilder
    private var kycBanner: some View {
        if !wallet.isKYCVerified {
            VStack(spacing: 12) {
                Text("🎉 Пройдите верификацию по фото и получите +50,000 $TYP0K!")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Button {
                    Haptics.medium()
                    showKYC = true
                } label: {
                    Text("Пройти KYC")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.white, in: Capsule())
                }
            }
            .padding(16)
            .background(
                LinearGradient(colors: [Color(red: 1.0, green: 0.72, blue: 0.2), Color(red: 1.0, green: 0.42, blue: 0.28)],
                               startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .transition(.opacity.combined(with: .scale(scale: 0.95)))
        }
    }

    // MARK: - Balances

    private var balancesCard: some View {
        VStack(spacing: 0) {
            balanceRow(
                icon: TokenIcon(text: "T", colors: [Color(red: 0.16, green: 0.32, blue: 0.72), Color(red: 0.36, green: 0.2, blue: 0.8)]),
                title: "$TYP0K Token",
                value: wallet.typ0kBalanceLabel
            )
            Divider().padding(.leading, 62)
            balanceRow(
                icon: TokenIcon(text: "₮", colors: [Color(red: 0.07, green: 0.62, blue: 0.52)]),
                title: "Tether USDT",
                value: wallet.usdtBalanceLabel
            )
        }
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
    }

    private func balanceRow(icon: TokenIcon, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            icon.frame(width: 38, height: 38)
            Text(title)
                .font(.subheadline.weight(.medium))
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func showToast(_ message: String) {
        toast = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if toast == message { toast = nil }
        }
    }
}

/// Small gradient token badge.
struct TokenIcon: View {
    let text: String
    let colors: [Color]

    var body: some View {
        ZStack {
            Circle().fill(LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing))
            Text(text)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}
