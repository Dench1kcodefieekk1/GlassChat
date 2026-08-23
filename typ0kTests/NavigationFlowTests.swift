import XCTest
@testable import typ0k

@MainActor
final class NavigationFlowTests: XCTestCase {
    // MARK: - Path logic (pure, no store needed)

    func testOpenChatAppendsChatRoute() {
        let model = ChatsViewModel()
        model.openChat("chat-1")
        XCTAssertEqual(model.path, [.chat("chat-1")])
    }

    func testPopToChatTruncatesDeeperRoutes() {
        let model = ChatsViewModel()
        model.openChat("chat-1")
        model.path.append(.profile("user-2"))

        model.popToChat("chat-1")

        XCTAssertEqual(model.path, [.chat("chat-1")])
    }

    func testPopToChatAppendsWhenChatNotOnStack() {
        let model = ChatsViewModel()
        model.popToChat("chat-9")
        XCTAssertEqual(model.path, [.chat("chat-9")])
    }

    // MARK: - Coordinator state

    func testPendingOpenChatIDStartsNil() {
        XCTAssertNil(AppState().pendingOpenChatID)
    }

    // MARK: - Compose selection flow

    func testStartChatDismissesComposeAndReportsChatID() {
        let store = makeStore()
        let model = ChatsViewModel()
        model.showCompose = true

        let chatID = model.startChat(with: "user-sarah", in: store)

        XCTAssertFalse(model.showCompose, "selecting a contact must dismiss the compose sheet")
        XCTAssertEqual(store.chat(id: chatID)?.memberIDs.contains("user-sarah"), true)
    }

    func testStartChatIsIdempotentPerContact() {
        let store = makeStore()
        let model = ChatsViewModel()

        let first = model.startChat(with: "user-john", in: store)
        let second = model.startChat(with: "user-john", in: store)

        XCTAssertEqual(first, second, "re-selecting a contact must reuse the existing direct chat")
    }

    // MARK: - Verification bot bootstrap

    func testEnsureVerificationBotCreatesChatUserAndIntroIdempotently() {
        let store = makeStore()

        store.ensureVerificationBot()

        XCTAssertNotNil(store.user(id: User.verificationBotID))
        XCTAssertEqual(store.user(id: User.verificationBotID)?.isVerified, true)
        XCTAssertEqual(store.user(id: User.verificationBotID)?.name, "Verification")
        let botChat = store.chats.first { $0.memberIDs.contains(User.verificationBotID) }
        XCTAssertNotNil(botChat, "bot chat must exist after bootstrap")
        XCTAssertEqual(store.sortedMessages(for: botChat!.id).count, 1, "bot chat gets exactly one intro message")

        // Second call must not duplicate anything.
        store.ensureVerificationBot()
        let botChats = store.chats.filter { $0.memberIDs.contains(User.verificationBotID) }
        XCTAssertEqual(botChats.count, 1)
        XCTAssertEqual(store.sortedMessages(for: botChat!.id).count, 1)
    }

    func testVerificationChatDetection() {
        let store = makeStore()
        store.ensureVerificationBot()

        let botChat = store.chats.first { $0.memberIDs.contains(User.verificationBotID) }
        XCTAssertNotNil(botChat)
        XCTAssertEqual(botChat?.memberIDs.contains(store.currentUserID), true)
    }

    // MARK: - Helpers

    private func makeStore() -> DataStore {
        let snapshot = Snapshot(
            currentUserID: "user-me",
            users: [
                User(id: "user-me", name: "Me", username: "me", bio: "", phone: ""),
                User(id: "user-sarah", name: "Sarah", username: "sarah", bio: "", phone: ""),
                User(id: "user-john", name: "John", username: "john", bio: "", phone: "")
            ],
            chats: [],
            messages: [],
            settings: AppSettings()
        )
        return DataStore(snapshot: snapshot)
    }
}
