import SwiftUI
import UIKit

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

enum ChatWallpaper: String, Codable, CaseIterable, Identifiable {
    case classic
    case gradient
    case minimal
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .classic: return "Default"
        case .gradient: return "Gradient"
        case .minimal: return "Minimal"
        case .dark: return "Dark"
        }
    }
}

struct ChatWallpaperView: View {
    let wallpaper: ChatWallpaper

    var body: some View {
        switch wallpaper {
        case .classic:
            Color(uiColor: .systemGroupedBackground)
        case .gradient:
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.14), .clear, Color.accentColor.opacity(0.09)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .minimal:
            Color(uiColor: .systemBackground)
        case .dark:
            ZStack {
                Color.black
                LinearGradient(
                    colors: [Color(uiColor: .systemIndigo).opacity(0.30), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}

enum BubbleStyle: String, Codable, CaseIterable, Identifiable {
    case rounded
    case compact

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rounded: return "Rounded"
        case .compact: return "Compact"
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .rounded: return AppTheme.bubbleRadius
        case .compact: return 10
        }
    }
}

enum NotificationSound: String, Codable, CaseIterable, Identifiable {
    case glass
    case chime
    case pop
    case none

    var id: String { rawValue }

    var label: String { rawValue.capitalized }
}

enum AutoLockOption: String, Codable, CaseIterable, Identifiable {
    case oneMinute
    case fiveMinutes
    case oneHour
    case never

    var id: String { rawValue }

    var label: String {
        switch self {
        case .oneMinute: return "1 minute"
        case .fiveMinutes: return "5 minutes"
        case .oneHour: return "1 hour"
        case .never: return "Never"
        }
    }
}

enum AppLanguage: String, Codable, CaseIterable, Identifiable {
    case system
    case english
    case russian
    case ukrainian

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .english: return "English"
        case .russian: return "Русский"
        case .ukrainian: return "Українська"
        }
    }
}

struct DeviceSession: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var deviceName: String
    var systemName: String
    var appVersion: String
    var location: String
    var lastActive: String
    var isCurrent: Bool

    static var defaults: [DeviceSession] {
        [
            DeviceSession(
                id: "session-this",
                deviceName: UIDevice.current.name,
                systemName: "iOS 26",
                appVersion: "typ0k 0.1",
                location: "Current location",
                lastActive: "Online",
                isCurrent: true
            ),
            DeviceSession(
                id: "session-pc",
                deviceName: "Windows PC",
                systemName: "Windows 11",
                appVersion: "typ0k Web 0.9",
                location: "Berlin, Germany",
                lastActive: "Last active today at 9:41",
                isCurrent: false
            ),
            DeviceSession(
                id: "session-ipad",
                deviceName: "iPad Pro",
                systemName: "iPadOS 26",
                appVersion: "typ0k 0.1",
                location: "Kyiv, Ukraine",
                lastActive: "Last active yesterday",
                isCurrent: false
            )
        ]
    }
}

struct LinkedAccount: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var name: String
    var phone: String
}

struct AppSettings: Codable, Equatable {
    var appearance: AppearanceMode = .system
    var accent: AccentChoice = .blue

    // Chats
    var enterToSend: Bool = true
    var messagePreviews: Bool = true
    var saveIncomingMedia: Bool = false
    var messageTextSize: Double = 17
    var wallpaper: ChatWallpaper = .classic
    var bubbleStyle: BubbleStyle = .rounded
    var autoDownloadPhotos: Bool = true
    var autoDownloadVideos: Bool = true
    var autoDownloadFiles: Bool = true
    var linkPreviews: Bool = true
    var autoPlayVideos: Bool = true

    // Notifications
    var notifyMessages: Bool = true
    var notifySounds: Bool = true
    var notificationSound: NotificationSound = .glass
    var notifyPreview: Bool = true
    var notifyMentions: Bool = true
    var notifyReactions: Bool = true
    var badgeCount: Bool = true
    var badgeIncludeMuted: Bool = false

    // Privacy
    var showLastSeen: Bool = true
    /// Tri-state replacement for `showLastSeen`: who may see this user's
    /// online status and last-seen timestamp (mirrored to Firestore).
    var lastSeenPrivacy: LastSeenPrivacy = .everyone
    var showProfilePhoto: Bool = true
    var showPhoneNumber: Bool = true
    var readReceipts: Bool = true
    var allowCalls: Bool = true
    var blockedUserIDs: [String] = []

    // Security (local prototype state only — not real protection)
    var passcodeEnabled: Bool = false
    var passcodeHash: String? = nil
    var autoLock: AutoLockOption = .fiveMinutes
    var twoStepEnabled: Bool = false
    var twoStepPasswordHash: String? = nil
    var recoveryEmail: String = ""

    // Sessions & accounts (demo)
    var sessions: [DeviceSession] = DeviceSession.defaults
    var linkedAccounts: [LinkedAccount] = []

    // Other
    var language: AppLanguage = .system

    enum CodingKeys: String, CodingKey {
        case appearance, accent, enterToSend, messagePreviews, saveIncomingMedia
        case messageTextSize, wallpaper, bubbleStyle
        case autoDownloadPhotos, autoDownloadVideos, autoDownloadFiles
        case linkPreviews, autoPlayVideos
        case notifyMessages, notifySounds, notificationSound, notifyPreview
        case notifyMentions, notifyReactions, badgeCount, badgeIncludeMuted
        case showLastSeen, lastSeenPrivacy, showProfilePhoto, showPhoneNumber, readReceipts
        case allowCalls, blockedUserIDs
        case passcodeEnabled, passcodeHash, autoLock
        case twoStepEnabled, twoStepPasswordHash, recoveryEmail
        case sessions, linkedAccounts, language
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appearance = try container.decodeIfPresent(AppearanceMode.self, forKey: .appearance) ?? .system
        accent = try container.decodeIfPresent(AccentChoice.self, forKey: .accent) ?? .blue
        enterToSend = try container.decodeIfPresent(Bool.self, forKey: .enterToSend) ?? true
        messagePreviews = try container.decodeIfPresent(Bool.self, forKey: .messagePreviews) ?? true
        saveIncomingMedia = try container.decodeIfPresent(Bool.self, forKey: .saveIncomingMedia) ?? false
        messageTextSize = try container.decodeIfPresent(Double.self, forKey: .messageTextSize) ?? 17
        wallpaper = try container.decodeIfPresent(ChatWallpaper.self, forKey: .wallpaper) ?? .classic
        bubbleStyle = try container.decodeIfPresent(BubbleStyle.self, forKey: .bubbleStyle) ?? .rounded
        autoDownloadPhotos = try container.decodeIfPresent(Bool.self, forKey: .autoDownloadPhotos) ?? true
        autoDownloadVideos = try container.decodeIfPresent(Bool.self, forKey: .autoDownloadVideos) ?? true
        autoDownloadFiles = try container.decodeIfPresent(Bool.self, forKey: .autoDownloadFiles) ?? true
        linkPreviews = try container.decodeIfPresent(Bool.self, forKey: .linkPreviews) ?? true
        autoPlayVideos = try container.decodeIfPresent(Bool.self, forKey: .autoPlayVideos) ?? true
        notifyMessages = try container.decodeIfPresent(Bool.self, forKey: .notifyMessages) ?? true
        notifySounds = try container.decodeIfPresent(Bool.self, forKey: .notifySounds) ?? true
        notificationSound = try container.decodeIfPresent(NotificationSound.self, forKey: .notificationSound) ?? .glass
        notifyPreview = try container.decodeIfPresent(Bool.self, forKey: .notifyPreview) ?? true
        notifyMentions = try container.decodeIfPresent(Bool.self, forKey: .notifyMentions) ?? true
        notifyReactions = try container.decodeIfPresent(Bool.self, forKey: .notifyReactions) ?? true
        badgeCount = try container.decodeIfPresent(Bool.self, forKey: .badgeCount) ?? true
        badgeIncludeMuted = try container.decodeIfPresent(Bool.self, forKey: .badgeIncludeMuted) ?? false
        showLastSeen = try container.decodeIfPresent(Bool.self, forKey: .showLastSeen) ?? true
        lastSeenPrivacy = try container.decodeIfPresent(LastSeenPrivacy.self, forKey: .lastSeenPrivacy)
            ?? (showLastSeen ? .everyone : .nobody)
        showProfilePhoto = try container.decodeIfPresent(Bool.self, forKey: .showProfilePhoto) ?? true
        showPhoneNumber = try container.decodeIfPresent(Bool.self, forKey: .showPhoneNumber) ?? true
        readReceipts = try container.decodeIfPresent(Bool.self, forKey: .readReceipts) ?? true
        allowCalls = try container.decodeIfPresent(Bool.self, forKey: .allowCalls) ?? true
        blockedUserIDs = try container.decodeIfPresent([String].self, forKey: .blockedUserIDs) ?? []
        passcodeEnabled = try container.decodeIfPresent(Bool.self, forKey: .passcodeEnabled) ?? false
        passcodeHash = try container.decodeIfPresent(String.self, forKey: .passcodeHash)
        autoLock = try container.decodeIfPresent(AutoLockOption.self, forKey: .autoLock) ?? .fiveMinutes
        twoStepEnabled = try container.decodeIfPresent(Bool.self, forKey: .twoStepEnabled) ?? false
        twoStepPasswordHash = try container.decodeIfPresent(String.self, forKey: .twoStepPasswordHash)
        recoveryEmail = try container.decodeIfPresent(String.self, forKey: .recoveryEmail) ?? ""
        sessions = try container.decodeIfPresent([DeviceSession].self, forKey: .sessions) ?? DeviceSession.defaults
        linkedAccounts = try container.decodeIfPresent([LinkedAccount].self, forKey: .linkedAccounts) ?? []
        language = try container.decodeIfPresent(AppLanguage.self, forKey: .language) ?? .system
    }
}
