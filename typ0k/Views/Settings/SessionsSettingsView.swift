import SwiftUI

struct SessionsSettingsView: View {
    @Environment(DataStore.self) private var store
    @State private var sessionToTerminate: DeviceSession?
    @State private var showTerminateAll = false

    private var sessions: [DeviceSession] { store.settings.sessions }
    private var otherSessions: [DeviceSession] { sessions.filter { !$0.isCurrent } }

    var body: some View {
        List {
            if let current = sessions.first(where: \.isCurrent) {
                Section("This Device") {
                    sessionRow(current)
                }
            }

            if !otherSessions.isEmpty {
                Section {
                    ForEach(otherSessions) { session in
                        sessionRow(session)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    sessionToTerminate = session
                                } label: {
                                    Label("Terminate", systemImage: "xmark.circle.fill")
                                }
                            }
                    }
                } header: {
                    Text("Active Sessions")
                } footer: {
                    Text("Swipe a session to terminate it, or terminate all other sessions at once below.")
                }

                Section {
                    Button(role: .destructive) {
                        showTerminateAll = true
                    } label: {
                        Label("Terminate All Other Sessions", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                Section {
                    Text("No other active sessions.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Active Sessions")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Terminate this session?",
            isPresented: Binding(
                get: { sessionToTerminate != nil },
                set: { if !$0 { sessionToTerminate = nil } }
            ),
            titleVisibility: .visible,
            presenting: sessionToTerminate
        ) { session in
            Button("Terminate", role: .destructive) {
                terminate(session)
            }
        } message: { session in
            Text("\(session.deviceName) will be signed out of typ0k.")
        }
        .confirmationDialog(
            "Terminate all other sessions?",
            isPresented: $showTerminateAll,
            titleVisibility: .visible
        ) {
            Button("Terminate All", role: .destructive) {
                terminateAllOthers()
            }
        } message: {
            Text("All sessions except this device will be signed out.")
        }
    }

    private func sessionRow(_ session: DeviceSession) -> some View {
        HStack(spacing: 12) {
            Image(systemName: session.isCurrent ? "iphone" : (session.deviceName.contains("iPad") ? "ipad" : "desktopcomputer"))
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(session.deviceName)
                        .font(.subheadline.weight(.semibold))
                    if session.isCurrent {
                        Text("This device")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.tint.opacity(0.15), in: Capsule())
                            .foregroundStyle(.tint)
                    }
                }
                Text("\(session.systemName) · \(session.appVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(session.location)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(session.lastActive)
                .font(.caption)
                .foregroundStyle(session.isCurrent ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 2)
    }

    private func terminate(_ session: DeviceSession) {
        guard !session.isCurrent else { return }
        Haptics.medium()
        store.settings.sessions.removeAll { $0.id == session.id }
        sessionToTerminate = nil
        store.save()
    }

    private func terminateAllOthers() {
        Haptics.medium()
        store.settings.sessions.removeAll { !$0.isCurrent }
        store.save()
    }
}
