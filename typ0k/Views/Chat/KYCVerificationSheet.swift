import SwiftUI
import PhotosUI

/// Photo KYC: pick a document photo, submit, and the +50,000 $TYP0K bonus
/// lands in the wallet with a receipt posted to the @wallet chat.
struct KYCVerificationSheet: View {
    let onVerified: () -> Void

    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var pickerItem: PhotosPickerItem?
    @State private var documentImage: UIImage?
    @State private var submitting = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                photoContainer

                Text("Загрузите фото документа (паспорт или ID). После проверки на ваш кошелёк будет начислено +50,000 $TYP0K.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Spacer(minLength: 0)

                Button {
                    submit()
                } label: {
                    HStack(spacing: 8) {
                        if submitting {
                            ProgressView().tint(.white)
                        }
                        Text("Подтвердить аккаунт")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        documentImage == nil
                            ? AnyShapeStyle(Color(uiColor: .systemGray3))
                            : AnyShapeStyle(Color.blue.gradient),
                        in: Capsule()
                    )
                }
                .disabled(documentImage == nil || submitting)
            }
            .padding(18)
            .navigationTitle("Верификация")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
            }
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        Haptics.light()
                        documentImage = image
                    }
                    pickerItem = nil
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Photo container

    private var photoContainer: some View {
        ZStack {
            if let documentImage {
                Image(uiImage: documentImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    VStack(spacing: 10) {
                        Image(systemName: "doc.viewfinder.fill")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundStyle(.tint)
                        Text("Выбрать фото документа")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.tint)
                        Text("PNG или JPG")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundStyle(.tint.opacity(0.5))
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 6)
    }

    // MARK: - Submit

    private func submit() {
        guard let documentImage else { return }
        submitting = true

        WalletManager.shared.verifyKYC(with: documentImage)
        Haptics.success()
        store.postSystemMessage(
            chatID: "chat-wallet",
            senderID: User.walletBotID,
            text: "✅ Верификация успешна! Вам начислено 50,000 $TYP0K. Баланс обновлен."
        )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            dismiss()
            onVerified()
        }
    }
}
