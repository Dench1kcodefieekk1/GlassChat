import XCTest
@testable import typ0k

@MainActor
final class UserLevelManagerTests: XCTestCase {
    // MARK: - Shape logic

    func testSymbolNamesAtLevelBoundaries() {
        XCTAssertEqual(UserLevelManager.symbolName(for: 1), "circle.fill")
        XCTAssertEqual(UserLevelManager.symbolName(for: 19), "circle.fill")
        XCTAssertEqual(UserLevelManager.symbolName(for: 20), "triangle.fill")
        XCTAssertEqual(UserLevelManager.symbolName(for: 39), "triangle.fill")
        XCTAssertEqual(UserLevelManager.symbolName(for: 40), "square.fill")
        XCTAssertEqual(UserLevelManager.symbolName(for: 59), "square.fill")
        XCTAssertEqual(UserLevelManager.symbolName(for: 60), "pentagon.fill")
        XCTAssertEqual(UserLevelManager.symbolName(for: 79), "pentagon.fill")
        XCTAssertEqual(UserLevelManager.symbolName(for: 80), "hexagon.fill")
        XCTAssertEqual(UserLevelManager.symbolName(for: 99), "hexagon.fill")
        XCTAssertEqual(UserLevelManager.symbolName(for: 100), "star.fill")
        XCTAssertEqual(UserLevelManager.symbolName(for: 499), "star.fill")
        XCTAssertEqual(UserLevelManager.symbolName(for: 500), "crown.fill")
    }

    // MARK: - Formulas

    func testRequiredXPFormula() {
        XCTAssertEqual(UserLevelManager.requiredXP(for: 1), 200)
        XCTAssertEqual(UserLevelManager.requiredXP(for: 2), 400)
        XCTAssertEqual(UserLevelManager.requiredXP(for: 25), 5000)
        XCTAssertEqual(UserLevelManager.requiredXP(for: 500), 100_000)
    }

    // MARK: - Message XP

    func testMessageXPIsBasePlusPerCharacter() {
        let manager = UserLevelManager(restoring: false)
        // 50 characters -> 10 + 50 = 60 XP.
        manager.addXPForMessage(text: String(repeating: "a", count: 50))
        XCTAssertEqual(manager.currentLevel, 1)
        XCTAssertEqual(manager.currentXP, 60)
    }

    func testLevelUpCarriesLeftoverXP() {
        let manager = UserLevelManager(restoring: false)
        // Five 45-char messages: 5 * (10 + 45) = 275 XP.
        // Level 1 needs 200 -> level 2 with 75 XP carried over.
        for _ in 0..<5 {
            manager.addXPForMessage(text: String(repeating: "b", count: 45))
        }
        XCTAssertEqual(manager.currentLevel, 2)
        XCTAssertEqual(manager.currentXP, 75)
    }

    // MARK: - Daily login bonus

    func testDailyLoginBonusAwardsOncePerDay() {
        let manager = UserLevelManager(restoring: false)
        // First-ever launch records the date but awards nothing so new
        // accounts start strictly at level 1.
        XCTAssertFalse(manager.registerDailyLoginBonus())
        XCTAssertEqual(manager.currentXP, 0)
        XCTAssertEqual(manager.currentLevel, 1)
        XCTAssertNotNil(manager.lastLoginDate)

        // Same-day launches never re-award.
        XCTAssertFalse(manager.registerDailyLoginBonus())
        XCTAssertEqual(manager.currentXP, 0)
    }

    // MARK: - Level cap

    func testLevelCapsAt500() {
        let manager = UserLevelManager(restoring: false)
        // Bulk XP past every threshold: sum of 200*L for L in 1...499.
        manager.addXP(200 * (1 + 499) * 499 / 2)
        XCTAssertEqual(manager.currentLevel, 500)
        XCTAssertEqual(manager.levelSymbolName, "crown.fill")
        XCTAssertEqual(manager.progress, 1)
    }
}
