import Foundation

/// Deterministic state machine behind the "Verification" system bot.
///
/// Pure logic (no SwiftUI / store dependencies) with an injectable clock so
/// the whole conversation flow — welcome, info, quiz challenge, lock-out,
/// and success — is unit-testable.
@MainActor
final class VerificationBotEngine {
    // MARK: Types

    struct QuizQuestion {
        let prompt: String
        let options: [String]
        let correctIndex: Int
    }

    struct BotMessage {
        let text: String
        let buttons: [InlineButton]?
    }

    struct Reaction {
        let messages: [BotMessage]
        /// True when the account just passed verification; the caller owns
        /// persisting `isVerified` and playing the celebration.
        let verified: Bool

        static func reply(_ text: String, buttons: [InlineButton]? = nil) -> Reaction {
            Reaction(messages: [BotMessage(text: text, buttons: buttons)], verified: false)
        }
    }

    enum Phase: Equatable {
        case idle
        case welcome
        case info
        case challenge(questionIndex: Int)
        case locked(until: Date)
        case verified
    }

    // MARK: Constants

    static let lockInterval: TimeInterval = 60

    static let welcomeButtons: [InlineButton] = [
        InlineButton(id: "bot-info", title: "Для чего нужна верификация", action: VerificationBotEngine.infoAction),
        InlineButton(id: "bot-start", title: "Получить верификацию", action: VerificationBotEngine.startChallengeAction)
    ]

    static let infoAction = "bot:info"
    static let startChallengeAction = "bot:start"
    static func answerAction(_ index: Int) -> String { "bot:answer:\(index)" }

    static let infoText = """
        Верификация подтверждает, что ваш аккаунт принадлежит реальному человеку, а не боту.

        Что даёт галочка:
        • Повышенное доверие — собеседники видят, что вы проверены.
        • Защита от подделки — никто не сможет выдать себя за вас.
        • Безопасность — подтверждённые аккаунты сложнее взломать и использовать для спама.

        Нажмите «Получить верификацию», чтобы пройти короткую проверку.
        """

    static let successText = "Верификация успешно пройдена! Галочка появится в течение пары минут."
    static let alreadyVerifiedText = "Вы уже прошли верификацию ✅ Ваш аккаунт подтверждён."
    static let lockedText = "Неверный ответ. Сессия временно заблокирована — попробуйте позже."
    static let welcomeText = "Добро пожаловать! Здесь вы можете подтвердить свою личность и получить галочку рядом с именем."
    static let startHint = "Отправьте /start, чтобы начать."

    let questions: [QuizQuestion] = [
        QuizQuestion(prompt: "Сколько будет 7 × 8?", options: ["54", "56", "48", "63"], correctIndex: 1),
        QuizQuestion(prompt: "Сколько дней в одной неделе?", options: ["5", "6", "7", "10"], correctIndex: 2),
        QuizQuestion(prompt: "Какое число идёт сразу после 9?", options: ["8", "10", "11", "19"], correctIndex: 1)
    ]

    // MARK: State

    private(set) var phase: Phase = .idle

    /// Action string of the correct answer while a challenge is active
    /// (exposed for unit tests and debugging).
    private(set) var currentCorrectAction: String?

    let now: () -> Date
    private var random = SystemRandomNumberGenerator()

    // MARK: Init

    init(now: @escaping () -> Date = { Date() }) {
        self.now = now
    }

    /// Locks expire on their own; callers see the resolved phase.
    var effectivePhase: Phase {
        if case .locked(let until) = phase, now() >= until {
            return .welcome
        }
        return phase
    }

    // MARK: Command handling

    func handle(command: String) -> Reaction {
        let text = command.trimmed.lowercased()
        let phase = effectivePhase

        guard text == "/start" else {
            switch phase {
            case .locked:
                return lockedNotice()
            case .challenge:
                return .reply("Выберите один из вариантов ответа выше 👆")
            case .verified:
                return .reply(Self.alreadyVerifiedText)
            default:
                return .reply(Self.startHint)
            }
        }

        switch phase {
        case .verified:
            return .reply(Self.alreadyVerifiedText)
        case .locked(let until):
            let seconds = Int(until.timeIntervalSince(now()))
            return .reply("Сессия заблокирована. Повторите попытку через \(seconds) сек.")
        default:
            self.phase = .welcome
            currentCorrectAction = nil
            return .reply(Self.welcomeText, buttons: Self.welcomeButtons)
        }
    }

    func handleButton(action: String) -> Reaction {
        let phase = effectivePhase

        switch action {
        case Self.infoAction:
            guard !isTerminal(phase) else { return .reply(Self.alreadyVerifiedText) }
            if case .locked = phase { return lockedNotice() }
            self.phase = .info
            return .reply(Self.infoText, buttons: Self.welcomeButtons)

        case Self.startChallengeAction:
            guard !isTerminal(phase) else { return .reply(Self.alreadyVerifiedText) }
            if case .locked = phase { return lockedNotice() }
            return presentChallenge()

        default:
            guard action.hasPrefix("bot:answer:"), let index = Int(action.dropFirst("bot:answer:".count)) else {
                return .reply(Self.startHint)
            }
            return submit(answerIndex: index)
        }
    }

    // MARK: Challenge

    private func presentChallenge() -> Reaction {
        let index = Int(random.next(upperBound: UInt32(questions.count)))
        let question = questions[index]
        self.phase = .challenge(questionIndex: index)
        currentCorrectAction = Self.answerAction(question.correctIndex)
        let buttons = question.options.enumerated().map { offset, option in
            InlineButton(id: "bot-answer-\(offset)", title: option, action: Self.answerAction(offset))
        }
        return Reaction(messages: [
            BotMessage(text: "Проверка: ответьте на вопрос.", buttons: nil),
            BotMessage(text: question.prompt, buttons: buttons)
        ], verified: false)
    }

    private func submit(answerIndex: Int) -> Reaction {
        guard case .challenge(let questionIndex) = effectivePhase,
              questionIndex < questions.count else {
            return .reply(Self.startHint)
        }
        let question = questions[questionIndex]

        guard answerIndex == question.correctIndex else {
            self.phase = .locked(until: now().addingTimeInterval(Self.lockInterval))
            currentCorrectAction = nil
            return .reply(Self.lockedText)
        }

        self.phase = .verified
        currentCorrectAction = nil
        return Reaction(messages: [BotMessage(text: Self.successText, buttons: nil)], verified: true)
    }

    // MARK: Helpers

    private func isTerminal(_ phase: Phase) -> Bool {
        if case .verified = phase { return true }
        return false
    }

    private func lockedNotice() -> Reaction {
        if case .locked(let until) = phase {
            let seconds = Int(until.timeIntervalSince(now()))
            return .reply("Сессия заблокирована. Повторите попытку через \(seconds) сек.")
        }
        return .reply(Self.lockedText)
    }
}
