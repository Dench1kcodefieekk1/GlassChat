import SwiftUI
import Observation

// MARK: - Styles

enum NicknameStyleID: String, CaseIterable, Identifiable {
    case standard
    case neonViolet
    case cyberGold
    case rainbow
    case fireCrown
    // Premium shader-style effects (rendered by AnimatedNicknameView)
    case burningText
    case rainbowWave
    case staticGlitch
    case neonPulse
    case galaxyText

    var id: String { rawValue }
}

struct NicknameStyleInfo: Identifiable {
    let id: NicknameStyleID
    let title: String
    let requiredLevel: Int

    static let all: [NicknameStyleInfo] = [
        NicknameStyleInfo(id: .standard, title: "Стандартный", requiredLevel: 1),
        NicknameStyleInfo(id: .neonViolet, title: "Neon Violet", requiredLevel: 10),
        NicknameStyleInfo(id: .cyberGold, title: "Cyber Gold", requiredLevel: 25),
        NicknameStyleInfo(id: .rainbow, title: "Радужный", requiredLevel: 50),
        NicknameStyleInfo(id: .fireCrown, title: "Fire & Crown", requiredLevel: 100),
        NicknameStyleInfo(id: .burningText, title: "BURNING TEXT", requiredLevel: 75),
        NicknameStyleInfo(id: .rainbowWave, title: "RAINBOW WAVE", requiredLevel: 75),
        NicknameStyleInfo(id: .staticGlitch, title: "STATIC GLITCH", requiredLevel: 75),
        NicknameStyleInfo(id: .neonPulse, title: "NEON PULSE", requiredLevel: 75),
        NicknameStyleInfo(id: .galaxyText, title: "GALAXY TEXT", requiredLevel: 150)
    ]
}

// MARK: - Manager

/// Discord-style nickname styling: gradient presets unlocked by account
/// level. Selection persists; the active style falls back to standard while
/// the account is below the required level.
@MainActor
@Observable
final class NicknameStyleManager {
    static let shared = NicknameStyleManager()

    private static let storageKey = "nickname.style"

    private(set) var selectedID: NicknameStyleID

    /// `restoring: false` gives tests a clean state.
    init(restoring: Bool = true) {
        if restoring,
           let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let saved = NicknameStyleID(rawValue: raw) {
            selectedID = saved
        } else {
            selectedID = .standard
        }
    }

    /// The style actually rendered: the selection when unlocked, otherwise
    /// the default white/dark-mode standard color.
    var activeID: NicknameStyleID {
        isUnlocked(selectedID, level: UserLevelManager.shared.currentLevel)
            ? selectedID
            : .standard
    }

    func isUnlocked(_ id: NicknameStyleID, level: Int) -> Bool {
        level >= Self.requiredLevel(for: id)
    }

    static func requiredLevel(for id: NicknameStyleID) -> Int {
        switch id {
        case .standard: return 1
        case .neonViolet: return 10
        case .cyberGold: return 25
        case .rainbow: return 50
        case .fireCrown: return 100
        case .burningText, .rainbowWave, .staticGlitch, .neonPulse: return 75
        case .galaxyText: return 150
        }
    }

    /// Selects a preset; locked presets are ignored.
    func select(_ id: NicknameStyleID) {
        guard isUnlocked(id, level: UserLevelManager.shared.currentLevel) else { return }
        selectedID = id
        UserDefaults.standard.set(id.rawValue, forKey: Self.storageKey)
    }
}

// MARK: - Rendering

/// Renders a display name in the active nickname style. Gradients are plain
/// `foregroundStyle`; the rainbow preset animates its spectrum on a
/// `TimelineView` (respecting Reduce Motion).
struct NicknameText: View {
    let name: String
    let style: NicknameStyleID
    var font: Font = .title2.weight(.semibold)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        switch style {
        case .standard:
            Text(name).font(font)
        case .neonViolet:
            Text(name)
                .font(font)
                .foregroundStyle(Self.violetGradient)
        case .cyberGold:
            Text(name)
                .font(font)
                .foregroundStyle(Self.goldGradient)
        case .fireCrown:
            // Ultra-bold display variant paired with the flame gradient.
            Text(name)
                .font(.system(.title2, design: .rounded).weight(.black))
                .foregroundStyle(Self.fireGradient)
        case .rainbow:
            TimelineView(.animation) { context in
                let time = context.date.timeIntervalSinceReferenceDate
                Text(name)
                    .font(font)
                    .foregroundStyle(
                        reduceMotion
                            ? Self.staticRainbow
                            : Self.animatedRainbow(at: time)
                    )
            }
        default:
            // Premium effects render via AnimatedNicknameView.
            Text(name).font(font)
        }
    }

    static let violetGradient = LinearGradient(
        colors: [Color(red: 0.66, green: 0.33, blue: 0.97), Color(red: 0.93, green: 0.28, blue: 0.60)],
        startPoint: .leading, endPoint: .trailing
    )

    static let goldGradient = LinearGradient(
        colors: [Color(red: 0.96, green: 0.56, blue: 0.04), Color(red: 1.0, green: 0.94, blue: 0.54)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let fireGradient = LinearGradient(
        colors: [Color(red: 0.94, green: 0.27, blue: 0.27), Color(red: 0.98, green: 0.45, blue: 0.09)],
        startPoint: .bottomLeading, endPoint: .topTrailing
    )

    static let staticRainbow = LinearGradient(
        colors: [.red, .yellow, .green, .cyan, .blue, .pink],
        startPoint: .leading, endPoint: .trailing
    )

    /// Spectrum shifted continuously by `time`.
    static func animatedRainbow(at time: TimeInterval) -> LinearGradient {
        let colors = (0..<6).map { index -> Color in
            let hue = (time * 0.09 + Double(index) * 0.4 / 6.0 * 2.4)
                .truncatingRemainder(dividingBy: 1)
            return Color(hue: hue < 0 ? hue + 1 : hue, saturation: 0.85, brightness: 1)
        }
        return LinearGradient(colors: colors, startPoint: .leading, endPoint: .trailing)
    }
}

/// Small gradient swatch used by the style picker rows.
struct NicknameStyleSwatch: View {
    let style: NicknameStyleID

    var body: some View {
        ZStack {
            switch style {
            case .standard:
                Circle().fill(Color(uiColor: .label).opacity(0.85))
            case .neonViolet:
                Circle().fill(NicknameText.violetGradient)
            case .cyberGold:
                Circle().fill(NicknameText.goldGradient)
            case .fireCrown:
                Circle().fill(NicknameText.fireGradient)
            case .rainbow:
                Circle().fill(NicknameText.staticRainbow)
            case .burningText:
                Circle().fill(LinearGradient(colors: [.yellow, .orange, .red],
                                             startPoint: .bottom, endPoint: .top))
            case .rainbowWave:
                Circle().fill(NicknameText.staticRainbow)
            case .staticGlitch:
                Circle().fill(LinearGradient(colors: [Color.red, .cyan],
                                             startPoint: .leading, endPoint: .trailing))
            case .neonPulse:
                Circle().fill(LinearGradient(colors: [Color.white, Color(red: 0.3, green: 0.5, blue: 1.0)],
                                             startPoint: .top, endPoint: .bottom))
            case .galaxyText:
                Circle().fill(LinearGradient(colors: [Color(red: 0.15, green: 0.08, blue: 0.35),
                                                      Color(red: 0.45, green: 0.2, blue: 0.85),
                                                      Color(red: 0.15, green: 0.65, blue: 0.95)],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            Text("A")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(style == .standard ? Color(uiColor: .systemBackground) : .white)
        }
        .frame(width: 26, height: 26)
    }
}
