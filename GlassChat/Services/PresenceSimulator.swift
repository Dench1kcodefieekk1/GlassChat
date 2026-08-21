import Foundation

@MainActor
enum PresenceSimulator {
    private static var task: Task<Void, Never>?

    static func start(store: DataStore) {
        task?.cancel()
        task = Task { [weak store] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(18))
                if Task.isCancelled { break }
                guard let store else { return }
                let candidates = store.users.values.filter { $0.id != store.currentUserID }
                guard let user = candidates.randomElement() else { continue }
                var updated = user
                updated.isOnline.toggle()
                updated.lastSeen = updated.isOnline ? nil : Date()
                store.users[user.id] = updated
                store.save()
            }
        }
    }

    static func stop() {
        task?.cancel()
        task = nil
    }
}
