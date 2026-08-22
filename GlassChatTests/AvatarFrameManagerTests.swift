import XCTest
@testable import GlassChat

@MainActor
final class AvatarFrameManagerTests: XCTestCase {
    func testCatalogHasTwentyDistinctFrames() {
        XCTAssertEqual(AvatarFrameManager.catalog.count, 20)
        XCTAssertEqual(Set(AvatarFrameManager.catalog.map(\.id)).count, 20)
    }

    func testStaticAndAnimatedTiers() {
        let staticFrames = AvatarFrameManager.catalog.filter { !$0.isAnimated }
        let animatedFrames = AvatarFrameManager.catalog.filter { $0.isAnimated }
        XCTAssertEqual(staticFrames.count, 10)
        XCTAssertEqual(animatedFrames.count, 10)
        XCTAssertTrue(staticFrames.allSatisfy { $0.requiredLevel >= 5 && $0.requiredLevel <= 40 })
        XCTAssertTrue(animatedFrames.allSatisfy { $0.requiredLevel >= 50 })
    }

    func testActiveFrameRespectsLevelGate() {
        let neon = AvatarFrameManager.frame(byID: "neonRing")!
        XCTAssertEqual(neon.requiredLevel, 5)

        XCTAssertNil(AvatarFrameManager.activeFrame(selectedID: "neonRing", level: 4))
        XCTAssertEqual(AvatarFrameManager.activeFrame(selectedID: "neonRing", level: 5), neon)
        XCTAssertNil(AvatarFrameManager.activeFrame(selectedID: nil, level: 500))
        XCTAssertNil(AvatarFrameManager.activeFrame(selectedID: "missing", level: 500))
    }

    func testEquipWritesSelectedFrameIdOntoSessionUser() {
        let store = makeStore()
        let gold = AvatarFrameManager.frame(byID: "cyberGold")!

        AvatarFrameManager.equip(gold, in: store)
        XCTAssertEqual(store.currentUser.selectedFrameId, "cyberGold")

        AvatarFrameManager.unequip(in: store)
        XCTAssertNil(store.currentUser.selectedFrameId)
    }

    func testLevelUpFiresCelebration() {
        let levels = UserLevelManager(restoring: false)
        levels.addXP(UserLevelManager.requiredXP(for: 1)) // level 1 -> 2
        XCTAssertEqual(levels.currentLevel, 2)
        XCTAssertEqual(LevelUpAudioNotifier.shared.celebrationLevel, 2,
                       "level-up must trigger the audio/celebration notifier")
    }

    private func makeStore() -> DataStore {
        let snapshot = Snapshot(
            currentUserID: "user-me",
            users: [User(id: "user-me", name: "Me", username: "me", bio: "", phone: "")],
            chats: [],
            messages: [],
            settings: AppSettings()
        )
        return DataStore(snapshot: snapshot)
    }
}
