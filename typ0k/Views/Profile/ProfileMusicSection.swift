import SwiftUI

/// "Saved Music" section shown at the bottom of the profile, listing audio
/// tracks saved from chat voice messages and shared `.mp3` files.
struct ProfileMusicSection: View {
    @ObservedObject private var music = MusicManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Saved Music")
                .font(.headline)

            if music.savedTracks.isEmpty {
                emptyState
            } else {
                VStack(spacing: 10) {
                    ForEach(music.savedTracks) { track in
                        SavedTrackRow(track: track)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: music.activeTrackID)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note.house")
                .font(.title2)
                .foregroundStyle(.tertiary)
            Text("No saved tracks yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
    }
}

// MARK: - Track row

private struct SavedTrackRow: View {
    let track: SavedAudioTrack
    @ObservedObject private var music = MusicManager.shared

    private var isActive: Bool { music.isActive(track) }
    private var isPlaying: Bool { isActive && music.isPlaying }

    var body: some View {
        HStack(spacing: 12) {
            disc

            VStack(alignment: .leading, spacing: 2) {
                Text(track.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(track.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(track.duration)
                .font(.caption.weight(.medium).monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .glassEffect(.regular, in: Capsule())
        }
        .padding(12)
        .background(
            Color(uiColor: .secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: music.activeTrackID)
    }

    // MARK: - Interactive disc artwork

    private var disc: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                music.toggle(track)
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: AppTheme.avatarColors(for: track.title),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "music.note")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .opacity(isPlaying ? 0.25 : 1)

                if isActive {
                    Circle()
                        .trim(from: 0, to: music.progress)
                        .stroke(.white.opacity(0.9), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .padding(3)
                        .rotationEffect(.degrees(-90))
                }

                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(7)
                    .background(.ultraThinMaterial, in: Circle())
                    .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
            }
            .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? "Pause \(track.title)" : "Play \(track.title)")
    }
}
