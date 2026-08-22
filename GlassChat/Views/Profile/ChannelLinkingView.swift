import SwiftUI

struct ChannelLinkingView: View {
    @Binding var selection: String
    @Environment(\.dismiss) private var dismiss

    static let demoChannels = [
        "GlassChat News",
        "Design Digest",
        "iOS Dev Weekly",
        "Liquid Glass Lab"
    ]

    var body: some View {
        List {
            Section {
                Button {
                    select("")
                } label: {
                    channelRow(name: "None", subtitle: "No linked channel", isSelected: selection.isEmpty)
                }
            }

            Section("Available Channels") {
                ForEach(Self.demoChannels, id: \.self) { channel in
                    Button {
                        select(channel)
                    } label: {
                        channelRow(
                            name: channel,
                            subtitle: "@\(channel.lowercased().replacingOccurrences(of: " ", with: ""))",
                            isSelected: selection == channel
                        )
                    }
                }
            }
        }
        .navigationTitle("Link a Channel")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func channelRow(name: String, subtitle: String, isSelected: Bool) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "megaphone.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(.tint.gradient, in: Circle())
            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
    }

    private func select(_ channel: String) {
        guard selection != channel else { return }
        Haptics.selection()
        selection = channel
        dismiss()
    }
}
