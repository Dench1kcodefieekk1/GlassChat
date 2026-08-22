import Foundation
import Observation

/// 500-level user activity & experience engine.
///
/// XP semantics: `currentXP` is the progress accumulated *within* the
/// current level; each level `L` requires `L * 200` XP to advance to `L + 1`.
/// The badge shape cycles through SF Symbols every 20 levels.
@MainActor
@Observable
final class UserLevelManager {
    static let shared = UserLevelManager()

    static let maxLevel = 500
    static let xpPerLevelMultiplier = 200
    static let dailyLoginBonus = 500
    static let messageBaseXP = 10

    private(set) var currentXP: Int
    private(set) var currentLevel: Int
    private(set) var lastLoginDate: Date?

    private static let storageKey = "userlevel.state"

    private struct State: Codable {
        var xp: Int
        var level: Int
        var lastLogin: Date?
    }

    /// `restoring: false` gives tests a pristine level-1 account.
    init(restoring: Bool = true) {
        if restoring,
           let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let state = try? JSONDecoder().decode(State.self, from: data) {
            currentXP = state.xp
            currentLevel = min(max(state.level, 1), Self.maxLevel)
            lastLoginDate = state.lastLogin
        } else {
            currentXP = 0
            currentLevel = 1
            lastLoginDate = nil
        }
    }

    // MARK: - Formulas

    /// XP required to advance from `level` to `level + 1` (level * 200).
    static func requiredXP(for level: Int) -> Int {
        level * xpPerLevelMultiplier
    }

    var requiredXP: Int { Self.requiredXP(for: currentLevel) }

    var progress: Double {
        if currentLevel >= Self.maxLevel { return 1 }
        guard requiredXP > 0 else { return 0 }
        return min(1, Double(currentXP) / Double(requiredXP))
    }

    // MARK: - Shape logic (SF Symbols only)

    /// Badge shape for a level: cycles every 20 levels, star from 100,
    /// crown at 500.
    static func symbolName(for level: Int) -> String {
        switch level {
        case ..<20: return "circle.fill"        // 1–19
        case 20..<40: return "triangle.fill"    // 20–39
        case 40..<60: return "square.fill"      // 40–59
        case 60..<80: return "pentagon.fill"    // 60–79
        case 80..<100: return "hexagon.fill"    // 80–99
        case 100..<500: return "star.fill"      // 100–499
        default: return "crown.fill"            // 500
        }
    }

    var levelSymbolName: String { Self.symbolName(for: currentLevel) }

    // MARK: - Earning rules

    /// Adds XP and cascades level-ups (XP carries over between levels).
    func addXP(_ amount: Int) {
        guard amount > 0 else { return }
        let previousLevel = currentLevel
        currentXP += amount
        while currentLevel < Self.maxLevel && currentXP >= requiredXP {
            currentXP -= requiredXP
            currentLevel += 1
        }
        if currentLevel >= Self.maxLevel {
            currentXP = min(currentXP, requiredXP)
        }
        persist()

        if currentLevel > previousLevel {
            // Sound effect + glowing celebration banner + success haptic.
            LevelUpAudioNotifier.shared.levelUp(to: currentLevel)
        }
    }

    /// +10 XP per message plus +1 XP per character.
    func addXPForMessage(text: String) {
        addXP(Self.messageBaseXP + text.count)
    }

    /// Daily login bonus: +500 XP on the first launch of the day.
    @discardableResult
    func registerDailyLoginBonus() -> Bool {
        if let lastLoginDate, Calendar.current.isDateInToday(lastLoginDate) {
            return false
        }
        lastLoginDate = Date()
        addXP(Self.dailyLoginBonus)
        return true
    }

    // MARK: - Persistence

    private func persist() {
        let state = State(xp: currentXP, level: currentLevel, lastLogin: lastLoginDate)
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
