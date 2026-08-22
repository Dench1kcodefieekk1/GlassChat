import Foundation
import UIKit
import Observation

/// Shared wallet state for the 2-in-1 ecosystem: the `@wallet` mini app and
/// the `@fragment` username market. Balances are observed directly by both
/// mini apps, so any change (KYC bonus, purchase) updates all UI instantly.
@MainActor
@Observable
final class WalletManager {
    static let shared = WalletManager()

    /// Flat state persisted to UserDefaults.
    private struct State: Codable {
        var typ0kBalance: Double
        var usdtBalance: Double
        var isKYCVerified: Bool
        var ownedUsernames: [String]
    }

    private static let storageKey = "wallet.state"
    static let kycBonus: Double = 50_000

    private(set) var typ0kBalance: Double
    private(set) var usdtBalance: Double
    private(set) var isKYCVerified: Bool
    private(set) var ownedUsernames: [String]

    /// `restoring: false` gives tests a pristine wallet.
    init(restoring: Bool = true) {
        if restoring,
           let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let state = try? JSONDecoder().decode(State.self, from: data) {
            typ0kBalance = state.typ0kBalance
            usdtBalance = state.usdtBalance
            isKYCVerified = state.isKYCVerified
            ownedUsernames = state.ownedUsernames
        } else {
            typ0kBalance = 500
            usdtBalance = 0.00
            isKYCVerified = false
            ownedUsernames = ["@alex"]
        }
    }

    // MARK: - Formatted output

    /// Estimated net worth in USD ($TYP0K pegged 1:1 for the prototype).
    var netWorthLabel: String {
        (typ0kBalance + usdtBalance).formatted(.currency(code: "USD"))
    }

    var typ0kBalanceLabel: String {
        typ0kBalance.formatted(.number.grouping(.automatic)) + " $TYP0K"
    }

    var usdtBalanceLabel: String {
        usdtBalance.formatted(.currency(code: "USD")) + " USDT"
    }

    // MARK: - KYC

    /// Photo KYC: flips verification and credits the +50,000 $TYP0K bonus.
    func verifyKYC(with documentImage: UIImage) {
        guard !isKYCVerified else { return }
        isKYCVerified = true
        typ0kBalance += Self.kycBonus
        persist()
    }

    // MARK: - Fragment purchases

    func canAfford(_ price: Double) -> Bool {
        typ0kBalance >= price
    }

    func owns(_ handle: String) -> Bool {
        ownedUsernames.contains(handle)
    }

    /// Deducts $TYP0K and records the handle. Returns false on insufficient
    /// funds or when the handle is already owned.
    @discardableResult
    func purchase(handle: String, price: Double) -> Bool {
        guard !owns(handle), canAfford(price) else { return false }
        typ0kBalance -= price
        ownedUsernames.append(handle)
        persist()
        return true
    }

    // MARK: - Persistence

    private func persist() {
        let state = State(
            typ0kBalance: typ0kBalance,
            usdtBalance: usdtBalance,
            isKYCVerified: isKYCVerified,
            ownedUsernames: ownedUsernames
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
