import SwiftUI
import Combine

struct OTPView: View {
    let phoneNumber: String
    var onAuthenticated: () -> Void
    var onBack: () -> Void

    private static let demoCode = "11111"
    private static let codeLength = 5

    @State private var code = ""
    @State private var errorMessage: String?
    @State private var succeeded = false
    @State private var resendSeconds = 30
    @FocusState private var focused: Bool

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("Enter Code")
                    .font(.largeTitle.bold())
                Text("We sent a verification code to")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(phoneNumber)
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.top, 32)

            codeCells
                .contentShape(Rectangle())
                .onTapGesture { focused = true }

            // Hidden field drives the keyboard and paste/OTP autofill.
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focused)
                .frame(width: 1, height: 1)
                .opacity(0.02)
                .accessibilityLabel("Verification code")

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .transition(.opacity)
            }

            VStack(spacing: 14) {
                if resendSeconds > 0 {
                    Text("Resend code in 0:\(String(format: "%02d", resendSeconds))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    Button("Resend Code") {
                        resendSeconds = 30
                        Haptics.light()
                    }
                    .font(.footnote.weight(.semibold))
                }

                Button {
                    onBack()
                } label: {
                    Label("Change Phone Number", systemImage: "phone.arrow.down.left")
                        .font(.footnote.weight(.medium))
                }
                .foregroundStyle(.tint)
            }

            Spacer()

            Text("Demo hint: the code is 11111")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 24)
        .navigationTitle("Verification")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focused = true }
        .onReceive(timer) { _ in
            if resendSeconds > 0 { resendSeconds -= 1 }
        }
        .onChange(of: code) { _, newValue in
            let digits = String(newValue.filter(\.isNumber).prefix(Self.codeLength))
            if digits != newValue { code = digits }
            errorMessage = nil
            if digits.count == Self.codeLength {
                verify(digits)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: errorMessage)
    }

    private var codeCells: some View {
        HStack(spacing: 12) {
            ForEach(0..<Self.codeLength, id: \.self) { index in
                cell(at: index)
            }
        }
    }

    @ViewBuilder
    private func cell(at index: Int) -> some View {
        let characters = Array(code)
        let isCurrent = index == characters.count && focused
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.75))
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            succeeded ? Color.green : (isCurrent ? Color.accentColor : .clear),
                            lineWidth: 2
                        )
                )

            if index < characters.count {
                Text(String(characters[index]))
                    .font(.title.bold())
                    .foregroundStyle(.primary)
                    .scaleEffect(succeeded ? 1.1 : 1)
            } else if isCurrent {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 6, height: 6)
                    .opacity(0.7)
            }
        }
        .frame(width: 52, height: 62)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: code)
    }

    private func verify(_ digits: String) {
        if digits == Self.demoCode {
            succeeded = true
            focused = false
            Haptics.success()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onAuthenticated()
            }
        } else {
            Haptics.error()
            errorMessage = "Incorrect code. Try 11111."
            code = ""
        }
    }
}
