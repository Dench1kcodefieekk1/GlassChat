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

    func testCreateDirectChatContainsSelectedContact() {
        let store = makeStore()

        let chat = store.createDirectChat(with: "user-sarah")

        XCTAssertTrue(chat.memberIDs.contains("user-sarah"))
        XCTAssertEqual(store.chat(id: chat.id)?.memberIDs.contains("user-sarah"), true)
    }

    func testCreateDirectChatIsIdempotentPerContact() {
        let store = makeStore()

        let first = store.createDirectChat(with: "user-john")
        let second = store.createDirectChat(with: "user-john")

        XCTAssertEqual(first.id, second.id, "re-selecting a contact must reuse the existing direct chat")
    }

    func testOpenDirectChatReusesDeterministicID() {
        let store = makeStore()
        let chatID = ChatService.directChatID(between: "user-me", and: "user-sarah")

        let first = store.openDirectChat(id: chatID, with: "user-sarah")
        let second = store.openDirectChat(id: chatID, with: "user-sarah")

        XCTAssertEqual(first.id, chatID)
        XCTAssertEqual(first.id, second.id)
        XCTAssertEqual(chatID, "user-me_user-sarah", "IDs must be sorted min_max")
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
