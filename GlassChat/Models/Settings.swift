import SwiftUI

enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AccentChoice: String, Codable, CaseIterable, Identifiable {
    case blue
    case indigo
    case teal
    case green
    case orange
    case pink

    var id: String { rawValue }

    var label: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .blue: return .blue
        case .indigo: return .indigo
        case .teal: return .teal
        case .green: return .green
        case .orange: return .orange
        case .pink: return .pink
        }
    }
}

struct AppSettings: Codable, Equatable {
    var appearance: AppearanceMode = .system
    var accent: AccentChoice = .blue

    // Chats
    var enterToSend: Bool = true
    var messagePreviews: Bool = true
    var autoDownloadMedia: Bool = true
    var saveIncomingMedia: Bool = false

    // Notifications
    var notifyMessages: Bool = true
    var notifySounds: Bool = true
    var notifyPreview: Bool = true
    var notifyMentions: Bool = true

    // Privacy
    var showLastSeen: Bool = true
    var showProfilePhoto: Bool = true
    var readReceipts: Bool = true
}
