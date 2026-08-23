import SwiftUI

enum AuthStep: Hashable {
    case phone
    case otp(String)
}

struct AuthFlowView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @Environment(DataStore.self) private var store
    @State private var path: [AuthStep] = []
    @State private var showAuthAlert = false
    @State private var authErrorMessage = ""

    var body: some View {
        NavigationStack(path: $path) {
            WelcomeView {
                Haptics.medium()
                path.append(.phone)
            }
            .navigationDestination(for: AuthStep.self) { step in
                switch step {
                case .phone:
                    PhoneNumberView { fullNumber in
                        path.append(.otp(fullNumber))
                    }
                case .otp(let number):
                    OTPView(
                        phoneNumber: number,
                        onAuthenticated: {
                            Haptics.success()
                            // The number entered at registration becomes the
                            // active session user's phone — the profile binds
                            // directly to currentUser.phone.
                            store.updateCurrentUserPhone(number)
                            // Live Firebase pipeline: signs in (or registers and
                            // provisions users/{uid}). On rejection the user is
                            // NOT admitted — an alert explains the failure.
                            Task {
                                do {
                                    try await AuthManager.shared.authenticateVerifiedPhone(number)
                                    isLoggedIn = true
                                } catch {
                                    authErrorMessage = error.localizedDescription
                                    showAuthAlert = true
                                }
                            }
                        },
                        onBack: {
                            if !path.isEmpty { path.removeLast() }
                        }
                    )
                }
            }
        }
        .alert("Sign-in failed", isPresented: $showAuthAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authErrorMessage)
        }
    }
}

struct WelcomeView: View {
    var onStart: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                Spacer()

                logo
                    .padding(.bottom, 28)
                    .scaleEffect(appeared ? 1 : 0.8)
                    .opacity(appeared ? 1 : 0)

                VStack(spacing: 10) {
                    Text("typ0k")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Messaging, redesigned for iOS.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

                Spacer()

                Button {
                    onStart()
                } label: {
                    Text("Start Messaging")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.glassProminent)
                .frame(maxWidth: 340)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    appeared = true
                }
            }
        }
    }

    private var logo: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [.accentColor.opacity(0.85), .accentColor.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 120, height: 120)

            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 46, weight: .semibold))
                .foregroundStyle(.white)
        }
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 34, style: .continuous))
        .shadow(color: .accentColor.opacity(0.25), radius: 24, y: 12)
        .accessibilityHidden(true)
    }

    private var background: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            Circle()
                .fill(.tint.opacity(0.16))
                .frame(width: 320, height: 320)
                .blur(radius: 40)
                .offset(x: -120, y: -260)

            Circle()
                .fill(.tint.opacity(0.12))
                .frame(width: 280, height: 280)
                .blur(radius: 44)
                .offset(x: 140, y: 280)

            Capsule()
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
                .frame(width: 170, height: 54)
                .glassEffect(.regular, in: Capsule())
                .rotationEffect(.degrees(-14))
                .offset(x: -110, y: -130)
                .accessibilityHidden(true)

            Capsule()
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.55))
                .frame(width: 140, height: 54)
                .glassEffect(.regular, in: Capsule())
                .rotationEffect(.degrees(10))
                .offset(x: 120, y: 150)
                .accessibilityHidden(true)
        }
    }
}
