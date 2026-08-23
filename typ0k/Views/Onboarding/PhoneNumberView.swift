import SwiftUI

struct PhoneNumberView: View {
    var onContinue: (String) -> Void

    @State private var selectedCountry = CountryCode.all[0]
    @State private var codeText = CountryCode.all[0].callingCode
    @State private var phoneDisplay = ""
    @State private var showCountryPicker = false
    @FocusState private var focusedField: Field?

    private enum Field { case code, phone }

    private var phoneDigits: String {
        phoneDisplay.filter(\.isNumber)
    }

    private var isValid: Bool {
        CountryCode.match(exact: codeText) != nil && phoneDigits.count >= 7
    }

    private var fullNumber: String {
        let code = codeText.hasPrefix("+") ? codeText : "+" + codeText
        return "\(code) \(phoneDisplay)"
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Text("Your Phone")
                    .font(.largeTitle.bold())
                Text("We will send a verification code to this number.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)

            HStack(spacing: 10) {
                codeField
                    .frame(width: 138)
                phoneField
            }
            .padding(.horizontal, 20)

            Button {
                Haptics.medium()
                onContinue(fullNumber)
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.glassProminent)
            .disabled(!isValid)
            .padding(.horizontal, 20)

            Spacer()
        }
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { focusedField = .code }
        .onChange(of: codeText) { _, newValue in
            if let match = CountryCode.match(exact: newValue) {
                selectedCountry = match
                if focusedField == .code {
                    focusedField = .phone
                }
            }
        }
        .onChange(of: phoneDisplay) { _, newValue in
            let digits = String(newValue.filter(\.isNumber).prefix(12))
            let formatted = Self.format(digits)
            if formatted != newValue {
                phoneDisplay = formatted
            }
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryPickerSheet(selected: selectedCountry) { country in
                selectedCountry = country
                codeText = country.callingCode
                focusedField = .phone
            }
        }
    }

    private var codeField: some View {
        HStack(spacing: 6) {
            Button {
                Haptics.selection()
                showCountryPicker = true
            } label: {
                Text(selectedCountry.flag)
                    .font(.title3)
            }
            .accessibilityLabel("Choose country")

            TextField("+380", text: $codeText)
                .keyboardType(.phonePad)
                .font(.body.weight(.medium))
                .focused($focusedField, equals: .code)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(fieldBackground)
    }

    private var phoneField: some View {
        TextField("67 123 45 67", text: $phoneDisplay)
            .keyboardType(.numberPad)
            .font(.body.weight(.medium))
            .focused($focusedField, equals: .phone)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(fieldBackground)
            .accessibilityLabel("Phone number")
    }

    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.7))
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    static func format(_ digits: String) -> String {
        let groups = [2, 3, 2, 2, 2, 2, 2]
        var parts: [String] = []
        var index = digits.startIndex
        for size in groups {
            guard index < digits.endIndex else { break }
            let end = digits.index(index, offsetBy: size, limitedBy: digits.endIndex) ?? digits.endIndex
            parts.append(String(digits[index..<end]))
            index = end
        }
        return parts.joined(separator: " ")
    }
}

struct CountryPickerSheet: View {
    let selected: CountryCode
    var onSelect: (CountryCode) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var results: [CountryCode] {
        let query = searchText.trimmed.lowercased()
        guard !query.isEmpty else { return CountryCode.all }
        let digits = query.replacingOccurrences(of: "+", with: "")
        return CountryCode.all.filter { country in
            country.name.lowercased().contains(query)
                || country.callingCode.replacingOccurrences(of: "+", with: "").hasPrefix(digits)
        }
    }

    var body: some View {
        NavigationStack {
            List(results) { country in
                Button {
                    Haptics.selection()
                    onSelect(country)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        Text(country.flag)
                            .font(.title3)
                        Text(country.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(country.callingCode)
                            .foregroundStyle(.secondary)
                        if country == selected {
                            Image(systemName: "checkmark")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.tint)
                        }
                    }
                }
            }
            .navigationTitle("Country")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search country or code")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .overlay {
                if results.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
