import XCTest
import UIKit
@testable import GlassChat

@MainActor
final class WalletManagerTests: XCTestCase {
    func testInitialState() {
        let wallet = WalletManager(restoring: false)
        XCTAssertEqual(wallet.typ0kBalance, 500)
        XCTAssertEqual(wallet.usdtBalance, 0.00)
        XCTAssertFalse(wallet.isKYCVerified)
        XCTAssertEqual(wallet.ownedUsernames, ["@alex"])
    }

    func testKYCVerificationCreditsBonusOnce() {
        let wallet = WalletManager(restoring: false)
        wallet.verifyKYC(with: UIImage())

        XCTAssertTrue(wallet.isKYCVerified)
        XCTAssertEqual(wallet.typ0kBalance, 50_500)
        XCTAssertEqual(wallet.typ0kBalanceLabel, "50,500 $TYP0K")
        XCTAssertEqual(wallet.netWorthLabel, "$50,500.00")

        // Double submission must not double-credit.
        wallet.verifyKYC(with: UIImage())
        XCTAssertEqual(wallet.typ0kBalance, 50_500)
    }

    func testPurchaseRequiresKYCBonusForExpensiveHandles() {
        let wallet = WalletManager(restoring: false)

        // 500 balance is not enough for @boss (10,000) before KYC.
        XCTAssertFalse(wallet.canAfford(10_000))
        XCTAssertFalse(wallet.purchase(handle: "@boss", price: 10_000))
        XCTAssertFalse(wallet.owns("@boss"))

        // With the +50,000 bonus the handle becomes purchasable.
        wallet.verifyKYC(with: UIImage())
        XCTAssertTrue(wallet.canAfford(10_000))
        XCTAssertTrue(wallet.purchase(handle: "@boss", price: 10_000))

        XCTAssertEqual(wallet.typ0kBalance, 50_500 - 10_000)
        XCTAssertTrue(wallet.owns("@boss"))

        // Buying the same handle twice is rejected.
        XCTAssertFalse(wallet.purchase(handle: "@boss", price: 10_000))
    }
}
