import SwiftUI

enum AppTheme {
    static let bubbleRadius: CGFloat = 18
    static let chatHorizontalPadding: CGFloat = 10

    private static let palette: [[Color]] = [
        [Color(red: 0.35, green: 0.42, blue: 0.95), Color(red: 0.55, green: 0.34, blue: 0.96)],
        [Color(red: 0.25, green: 0.55, blue: 0.95), Color(red: 0.20, green: 0.78, blue: 0.90)],
        [Color(red: 0.15, green: 0.68, blue: 0.62), Color(red: 0.35, green: 0.80, blue: 0.45)],
        [Color(red: 0.95, green: 0.55, blue: 0.25), Color(red: 0.95, green: 0.35, blue: 0.45)],
        [Color(red: 0.85, green: 0.30, blue: 0.50), Color(red: 0.95, green: 0.50, blue: 0.35)],
        [Color(red: 0.55, green: 0.35, blue: 0.90), Color(red: 0.85, green: 0.35, blue: 0.70)],
        [Color(red: 0.20, green: 0.70, blue: 0.85), Color(red: 0.35, green: 0.50, blue: 0.95)],
        [Color(red: 0.45, green: 0.75, blue: 0.30), Color(red: 0.15, green: 0.65, blue: 0.55)]
    ]

    static func avatarColors(for seed: String) -> [Color] {
        let value = seed.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return palette[abs(value) % palette.count]
    }
}

extension Date {
    var timeLabel: String {
        formatted(date: .omitted, time: .shortened)
    }

    var chatListLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return timeLabel }
        if let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()), self > weekAgo {
            return formatted(.dateTime.weekday(.abbreviated))
        }
        return formatted(.dateTime.day().month(.abbreviated))
    }

    var daySeparatorLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Today" }
        if calendar.isDateInYesterday(self) { return "Yesterday" }
        if calendar.isDate(self, equalTo: Date(), toGranularity: .year) {
            return formatted(.dateTime.day().month(.wide))
        }
        return formatted(.dateTime.day().month(.wide).year())
    }

    var lastSeenLabel: String {
        if Calendar.current.isDateInToday(self) {
            return "last seen at \(timeLabel)"
        }
        return "last seen \(formatted(.dateTime.day().month(.abbreviated)))"
    }
}

extension TimeInterval {
    var durationLabel: String {
        let total = Int(max(0, rounded()))
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isEmojiOnly: Bool {
        guard !isEmpty, unicodeScalars.count <= 8 else { return false }
        return unicodeScalars.allSatisfy { scalar in
            scalar.properties.isEmoji && (scalar.properties.isEmojiPresentation || scalar.value > 0x238C)
        }
    }
}
