import XCTest
@testable import GlassChat

@MainActor
final class NicknameStyleManagerTests: XCTestCase {
    func testRequiredLevelsMatchSpec() {
        XCTAssertEqual(NicknameStyleManager.requiredLevel(for: .standard), 1)
        XCTAssertEqual(NicknameStyleManager.requiredLevel(for: .neonViolet), 10)
        XCTAssertEqual(NicknameStyleManager.requiredLevel(for: .cyberGold), 25)
        XCTAssertEqual(NicknameStyleManager.requiredLevel(for: .rainbow), 50)
        XCTAssertEqual(NicknameStyleManager.requiredLevel(for: .fireCrown), 100)
    }

    func testLockedStyleCannotBeSelected() {
        let styles = NicknameStyleManager(restoring: false)
        let levels = UserLevelManager(restoring: false) // level 1

        XCTAssertFalse(styles.isUnlocked(.rainbow, level: levels.currentLevel))
        styles.select(.rainbow)
        XCTAssertEqual(styles.selectedID, .standard, "locked presets are ignored")
    }

    func testActiveFallsBackToStandardWhileLocked() {
        let styles = NicknameStyleManager(restoring: false)
        let levels = UserLevelManager(restoring: false)
        _ = levels

        // Level 1 account: everything beyond standard is inactive.
        XCTAssertEqual(styles.activeID, .standard)

        styles.select(.neonViolet)
        XCTAssertEqual(styles.activeID, .standard, "below level 10 the violet style must not render")
    }

    func testUnlockedStyleBecomesActive() {
        let styles = NicknameStyleManager(restoring: false)
        let levels = UserLevelManager(restoring: false)

        // Climb to level 25+ (Cyber Gold unlock): level 12 costs 200*L XP,
        // so 200 * (1...11) XP lands on level 12; add more for 25.
        levels.addXP(200 * (1...24).reduce(0, +))
        XCTAssertGreaterThanOrEqual(levels.currentLevel, 25)

        styles.select(.cyberGold)
        XCTAssertEqual(styles.selectedID, .cyberGold)
        XCTAssertEqual(styles.activeID, .cyberGold)

        // Rainbow (50) stays locked at ~25.
        styles.select(.rainbow)
        XCTAssertEqual(styles.activeID, .cyberGold)
    }
}
