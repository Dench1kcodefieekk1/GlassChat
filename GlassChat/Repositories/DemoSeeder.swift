import UIKit

enum DemoSeeder {
    static func makeSnapshot() -> Snapshot {
        let now = Date()
        func ago(_ hours: Double) -> Date { now.addingTimeInterval(-hours * 3600) }

        // MARK: Users

        let me = User(id: "user-me", name: "Alex", username: "alex",
                      bio: "Building delightful iOS things.", phone: "+1 555 0100")
        let sarah = User(id: "user-sarah", name: "Sarah Chen", username: "sarahc",
                         bio: "Product designer. Glass enthusiast.", phone: "+1 555 0101",
                         isVerified: true, isOnline: true)
        let john = User(id: "user-john", name: "John Carter", username: "johnc",
                        bio: "Swift, coffee, repeat.", phone: "+1 555 0102",
                        lastSeen: ago(0.4))
        let maya = User(id: "user-maya", name: "Maya Patel", username: "mayap",
                        bio: "Design systems and motion.", phone: "+1 555 0103",
                        isOnline: true)
        let leo = User(id: "user-leo", name: "Leo Novak", username: "leon",
                       bio: "Shipping things that feel great.", phone: "+1 555 0104",
                       lastSeen: ago(3))
        let mom = User(id: "user-mom", name: "Mom", username: "mom",
                       bio: "", phone: "+1 555 0105", lastSeen: ago(1))
        let dad = User(id: "user-dad", name: "Dad", username: "dad",
                       bio: "", phone: "+1 555 0106", lastSeen: ago(5))
        let priya = User(id: "user-priya", name: "Priya Sharma", username: "priya",
                         bio: "iOS at heart.", phone: "+1 555 0107",
                         isVerified: true, lastSeen: ago(0.2))
        let tom = User(id: "user-tom", name: "Tom Reed", username: "tomr",
                       bio: "", phone: "+1 555 0108", lastSeen: ago(26))

        let users = [me, sarah, john, maya, leo, mom, dad, priya, tom]

        // MARK: Generated media

        let moodBoardImage = saveGeneratedImage(colors: [
            UIColor(red: 0.36, green: 0.42, blue: 0.95, alpha: 1),
            UIColor(red: 0.85, green: 0.35, blue: 0.70, alpha: 1)
        ])
        let conceptImage = saveGeneratedImage(colors: [
            UIColor(red: 0.15, green: 0.65, blue: 0.60, alpha: 1),
            UIColor(red: 0.25, green: 0.55, blue: 0.95, alpha: 1)
        ])

        // MARK: Messages

        func incoming(_ id: String, _ chatID: String, _ sender: String, _ text: String, _ at: Date) -> Message {
            Message(id: id, chatID: chatID, senderID: sender, text: text, createdAt: at, status: .read)
        }
        func outgoing(_ id: String, _ chatID: String, _ text: String, _ at: Date) -> Message {
            Message(id: id, chatID: chatID, senderID: me.id, text: text, createdAt: at, status: .read)
        }

        var messages: [Message] = []

        // Sarah (direct) — 1 unread
        messages.append(incoming("m-s1", "chat-sarah", sarah.id,
                                 "Hey Alex! Did you get a chance to look at the new onboarding flow?", ago(26)))
        messages.append(outgoing("m-s2", "chat-sarah",
                                 "Yes! The glass navigation looks stunning 😍", ago(25.5)))
        messages.append(incoming("m-s3", "chat-sarah", sarah.id,
                                 "Right?? Liquid Glass was made for this app.", ago(25)))
        var moodMessage = incoming("m-s4", "chat-sarah", sarah.id, "Here's the mood board for the next sprint ✨", ago(24))
        moodMessage.attachments = [Attachment(id: "att-s4", kind: .image, fileName: moodBoardImage)]
        messages.append(moodMessage)
        messages.append(incoming("m-s5", "chat-sarah", sarah.id,
                                 "I'll push the updated mockups tonight.", ago(2)))

        // Design Team (group, pinned)
        messages.append(incoming("m-d1", "chat-design", maya.id, "Standup in 10 minutes!", ago(72)))
        messages.append(incoming("m-d2", "chat-design", leo.id, "Shipping the new build today 🚀", ago(26)))
        var conceptMessage = outgoing("m-d3", "chat-design", "Concept v2 — thoughts?", ago(24))
        conceptMessage.attachments = [Attachment(id: "att-d3", kind: .image, fileName: conceptImage)]
        messages.append(conceptMessage)
        messages.append(incoming("m-d4", "chat-design", maya.id,
                                 "Love the direction. The corner radii feel right.", ago(23.5)))
        messages.append(incoming("m-d5", "chat-design", leo.id,
                                 "Uploaded the new icon concepts to the shared folder.", ago(4)))

        // John (direct)
        messages.append(incoming("m-j1", "chat-john", john.id, "Did you watch the keynote?", ago(50)))
        messages.append(outgoing("m-j2", "chat-john", "Every second. The new APIs are wild.", ago(49.9)))
        messages.append(incoming("m-j3", "chat-john", john.id,
                                 "We should try building something with it.", ago(30)))
        messages.append(outgoing("m-j4", "chat-john", "This weekend?", ago(20)))

        // Family (group) — 2 unread
        messages.append(incoming("m-f1", "chat-family", mom.id, "Dinner on Sunday?", ago(5)))
        messages.append(incoming("m-f2", "chat-family", dad.id, "I'm bringing dessert 🍰", ago(4)))

        // iOS Developers (group, muted)
        messages.append(incoming("m-i1", "chat-iosdev", priya.id,
                                 "Anyone else seeing layout issues with the new glass toolbar?", ago(6)))
        messages.append(incoming("m-i2", "chat-iosdev", tom.id,
                                 "Works fine on device, broken in preview 🤷", ago(5)))

        // MARK: Chats

        func lastText(_ chatID: String) -> String {
            guard let last = messages.filter({ $0.chatID == chatID }).sorted(by: { $0.createdAt < $1.createdAt }).last else {
                return ""
            }
            return MessagePreviewText.preview(for: last, users: users)
        }
        func lastDate(_ chatID: String) -> Date? {
            messages.filter { $0.chatID == chatID }.map(\.createdAt).max()
        }

        let chats = [
            Chat(id: "chat-design", kind: .group, title: "Design Team",
                 memberIDs: [me.id, sarah.id, maya.id, leo.id],
                 isPinned: true,
                 lastMessageAt: lastDate("chat-design"),
                 lastMessagePreview: lastText("chat-design")),
            Chat(id: "chat-sarah", kind: .direct, title: sarah.name,
                 memberIDs: [me.id, sarah.id],
                 unreadCount: 1,
                 lastMessageAt: lastDate("chat-sarah"),
                 lastMessagePreview: lastText("chat-sarah")),
            Chat(id: "chat-john", kind: .direct, title: john.name,
                 memberIDs: [me.id, john.id],
                 lastMessageAt: lastDate("chat-john"),
                 lastMessagePreview: lastText("chat-john")),
            Chat(id: "chat-family", kind: .group, title: "Family",
                 memberIDs: [me.id, mom.id, dad.id],
                 unreadCount: 2,
                 lastMessageAt: lastDate("chat-family"),
                 lastMessagePreview: lastText("chat-family")),
            Chat(id: "chat-iosdev", kind: .group, title: "iOS Developers",
                 memberIDs: [me.id, priya.id, tom.id, sarah.id, john.id],
                 isMuted: true,
                 lastMessageAt: lastDate("chat-iosdev"),
                 lastMessagePreview: lastText("chat-iosdev"))
        ]

        return Snapshot(
            currentUserID: me.id,
            users: users,
            chats: chats,
            messages: messages,
            settings: AppSettings()
        )
    }

    private static func saveGeneratedImage(colors: [UIColor]) -> String {
        let size = CGSize(width: 900, height: 1200)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            let cg = context.cgContext
            let colorspace = CGColorSpaceCreateDeviceRGB()
            if let gradient = CGGradient(colorsSpace: colorspace,
                                         colors: colors.map { $0.cgColor } as CFArray,
                                         locations: [0, 1]) {
                cg.drawLinearGradient(gradient,
                                      start: .zero,
                                      end: CGPoint(x: size.width, y: size.height),
                                      options: [])
            }
            cg.setFillColor(UIColor.white.withAlphaComponent(0.16).cgColor)
            cg.fillEllipse(in: CGRect(x: size.width * 0.45, y: -size.height * 0.18,
                                      width: size.width * 0.9, height: size.width * 0.9))
            cg.fillEllipse(in: CGRect(x: -size.width * 0.3, y: size.height * 0.55,
                                      width: size.width * 0.8, height: size.width * 0.8))
        }
        let data = image.jpegData(compressionQuality: 0.85) ?? Data()
        return MediaService.save(data, extension: "jpg")
    }
}

/// Lightweight preview helper used during seeding (before a DataStore exists).
enum MessagePreviewText {
    static func preview(for message: Message, users: [User]) -> String {
        if let attachment = message.attachments.first {
            switch attachment.kind {
            case .image:
                return message.text.isEmpty ? "Photo" : "Photo · \(message.text)"
            case .voice:
                return "Voice message"
            case .file:
                return attachment.displayName ?? "File"
            }
        }
        return message.text
    }
}
