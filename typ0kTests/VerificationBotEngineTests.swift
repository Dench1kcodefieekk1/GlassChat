import XCTest
@testable import typ0k

/// Reference-type clock so the engine's injected `now` advances in tests.
@MainActor
private final class MutableClock {
    var date = Date(timeIntervalSince1970: 1_700_000_000)

    func advance(_ seconds: TimeInterval) {
        date = date.addingTimeInterval(seconds)
    }
}

@MainActor
final class VerificationBotEngineTests: XCTestCase {
    private var clock: MutableClock!
    private var engine: VerificationBotEngine!

    override func setUp() {
        super.setUp()
        clock = MutableClock()
        engine = VerificationBotEngine(now: { [clock] in clock.date })
    }

    // MARK: - /start flow

    func testStartShowsWelcomeWithTwoInlineButtons() {
        let reaction = engine.handle(command: "/start")

        XCTAssertEqual(reaction.messages.count, 1)
        XCTAssertEqual(reaction.messages[0].text, VerificationBotEngine.welcomeText)
        XCTAssertEqual(reaction.messages[0].buttons?.map(\.title), [
            "Для чего нужна верификация",
            "Получить верификацию"
        ])
        XCTAssertEqual(engine.phase, .welcome)
        XCTAssertFalse(reaction.verified)
    }

    func testNonCommandTextBeforeStartAsksForStart() {
        let reaction = engine.handle(command: "привет")
        XCTAssertEqual(reaction.messages.first?.text, VerificationBotEngine.startHint)
    }

    // MARK: - Info

    func testInfoButtonExplainsVerificationBenefits() {
        _ = engine.handle(command: "/start")
        let reaction = engine.handleButton(action: VerificationBotEngine.infoAction)

        XCTAssertEqual(reaction.messages.first?.text, VerificationBotEngine.infoText)
        XCTAssertEqual(engine.phase, .info)
        XCTAssertFalse(reaction.verified)
    }

    // MARK: - Challenge

    func testChallengePresentsFourAnswerOptions() {
        _ = engine.handle(command: "/start")
        let reaction = engine.handleButton(action: VerificationBotEngine.startChallengeAction)

        let buttons = reaction.messages.last?.buttons
        XCTAssertEqual(buttons?.count, 4)

        if case .challenge(let index) = engine.phase {
            XCTAssertTrue((0..<engine.questions.count).contains(index))
        } else {
            XCTFail("expected challenge phase, got \(engine.phase)")
        }
    }

    func testCorrectAnswerMarksReactionVerified() {
        _ = engine.handle(command: "/start")
        _ = engine.handleButton(action: VerificationBotEngine.startChallengeAction)
        guard let correctAction = engine.currentCorrectAction else {
            return XCTFail("no correct action while challenge active")
        }

        let reaction = engine.handleButton(action: correctAction)

        XCTAssertTrue(reaction.verified)
        XCTAssertEqual(reaction.messages.first?.text, VerificationBotEngine.successText)
        XCTAssertEqual(engine.phase, .verified)
    }

    // MARK: - Lock-out

    func testWrongAnswerLocksSessionAndBlocksEverything() {
        _ = engine.handle(command: "/start")
        _ = engine.handleButton(action: VerificationBotEngine.startChallengeAction)
        let wrongAction = self.wrongAnswerAction()

        let reaction = engine.handleButton(action: wrongAction)
        XCTAssertFalse(reaction.verified)

        guard case .locked(let until) = engine.phase else {
            return XCTFail("expected lock, got \(engine.phase)")
        }
        XCTAssertEqual(until.timeIntervalSince(clock.date), VerificationBotEngine.lockInterval, accuracy: 0.5)

        // While locked: /start and the challenge button are both refused.
        XCTAssertTrue(engine.handle(command: "/start").messages.first?.text.contains("заблокирована") ?? false)
        XCTAssertTrue(
            engine.handleButton(action: VerificationBotEngine.startChallengeAction)
                .messages.first?.text.contains("заблокирована") ?? false
        )
        XCTAssertEqual(engine.phase, .locked(until: until))
    }

    func testLockExpiresAndAllowsFreshStart() {
        _ = engine.handle(command: "/start")
        _ = engine.handleButton(action: VerificationBotEngine.startChallengeAction)
        _ = engine.handleButton(action: wrongAnswerAction())

        clock.advance(VerificationBotEngine.lockInterval + 1)

        XCTAssertEqual(engine.effectivePhase, .welcome)
        let reaction = engine.handle(command: "/start")
        XCTAssertEqual(reaction.messages.first?.text, VerificationBotEngine.welcomeText)
        XCTAssertEqual(engine.phase, .welcome)
    }

    // MARK: - Terminal state

    func testVerifiedAccountCannotRestartFlow() {
        completeVerification()

        XCTAssertEqual(engine.handle(command: "/start").messages.first?.text, VerificationBotEngine.alreadyVerifiedText)
        XCTAssertEqual(
            engine.handleButton(action: VerificationBotEngine.startChallengeAction).messages.first?.text,
            VerificationBotEngine.alreadyVerifiedText
        )
        XCTAssertEqual(engine.phase, .verified)
    }

    func testAnswerWithoutChallengeAsksForStart() {
        let reaction = engine.handleButton(action: VerificationBotEngine.answerAction(0))
        XCTAssertEqual(reaction.messages.first?.text, VerificationBotEngine.startHint)
    }

    // MARK: - Helpers

    private func completeVerification() {
        _ = engine.handle(command: "/start")
        _ = engine.handleButton(action: VerificationBotEngine.startChallengeAction)
        guard let correctAction = engine.currentCorrectAction else {
            return XCTFail("no correct action while challenge active")
        }
        _ = engine.handleButton(action: correctAction)
    }

    /// Derives a wrong answer from the active challenge's correct index.
    private func wrongAnswerAction() -> String {
        guard let correctAction = engine.currentCorrectAction,
              let correctIndex = Int(correctAction.dropFirst("bot:answer:".count)) else {
            XCTFail("no active challenge")
            return VerificationBotEngine.answerAction(-1)
        }
        return VerificationBotEngine.answerAction((correctIndex + 1) % 4)
    }
}

// MARK: - Delayed completion service

@MainActor
final class VerificationManagerTests: XCTestCase {
    func testCompletionVerifiesUserAndAppendsGiftPill() async throws {
        let snapshot = Snapshot(
            currentUserID: "user-me",
            users: [User(id: "user-me", name: "Me", username: "me", bio: "", phone: "")],
            chats: [],
            messages: [],
            settings: AppSettings()
        )
        let store = DataStore(snapshot: snapshot)
        store.ensureVerificationBot()
        let botChat = try XCTUnwrap(store.chats.first { $0.memberIDs.contains(User.verificationBotID) })

        let manager = VerificationManager(delay: { 0 })
        XCTAssertFalse(store.currentUser.isVerified)

        manager.scheduleCompletion(in: store, chatID: botChat.id)
        // Delay is injected as 0; give the MainActor task time to run.
        try await Task.sleep(for: .milliseconds(400))

        XCTAssertTrue(store.currentUser.isVerified, "user must flip to verified globally")
        XCTAssertTrue(
            store.sortedMessages(for: botChat.id).contains {
                $0.isSystemPill && $0.text == "Ваш аккаунт верифицирован"
            },
            "gift pill must be appended to the chat history"
        )
        XCTAssertEqual(manager.celebrationChatID, botChat.id)
        XCTAssertNotNil(manager.pendingPillID)
    }
}
