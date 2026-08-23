import SwiftUI

struct PhoneNumberView: View {
    var onContinue: (String) -> Void

    static let anonymousCode = "+7777"
    static let anonymousMessage =
        "Anonymous numbers (+7777) cannot be registered. Please use a valid mobile phone number."

    private static let defaultCountry =
        CountryCode.country(regionCode: Locale.current.region?.identifier ?? "")
        ?? CountryCode.country(regionCode: "UA")
        ?? CountryCode.all[0]

    @State private var selectedCountry = PhoneNumberView.defaultCountry
    @State private var codeText = "+"
    @State private var phoneDisplay = ""
    @State private var showCountryPicker = false
    @State private var showAnonymousAlert = false
    @FocusState private var focusedField: Field?

    private enum Field { case code, phone }

    private var phoneDigits: String {
        phoneDisplay.filter(\.isNumber)
    }

    private var normalizedCode: String {
        codeText.hasPrefix("+") ? codeText : "+" + codeText
    }

    /// Full E.164-style digit string: calling code digits + national number.
    private var fullDigits: String {
        normalizedCode.dropFirst().filter(\.isNumber) + phoneDigits
    }

    private var isAnonymousNumber: Bool {
        normalizedCode == Self.anonymousCode || fullDigits.hasPrefix("7777")
    }

    private var isValid: Bool {
        CountryCode.match(exact: normalizedCode) != nil
            && phoneDigits.count >= 7
            && !isAnonymousNumber
    }

    private var fullNumber: String {
        "\(normalizedCode) \(phoneDisplay)"
    }

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Your Phone")
                    .font(.largeTitle.bold())
                Text("We will send a verification code to this number.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)

            countrySelector

            HStack(spacing: 10) {
                codeField
                    .frame(width: 120)
                phoneField
            }

            if isAnonymousNumber {
                Text(Self.anonymousMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }

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

            Spacer()
        }
        .padding(.horizontal, 20)
        .navigationTitle("Sign In")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear { focusedField = .code }
        .onChange(of: codeText) { _, newValue in
            var text = newValue
            if !text.hasPrefix("+") { text = "+" + text.filter(\.isNumber) }
            text = "+" + String(text.dropFirst().filter(\.isNumber).prefix(4))
            if text != newValue { codeText = text; return }
            // Live country resolution: the selector mirrors what is typed.
            if let match = CountryCode.match(prefix: text) {
                selectedCountry = match
            }
            if CountryCode.match(exact: text) != nil && focusedField == .code {
                focusedField = .phone
            }
            if text == Self.anonymousCode {
                showAnonymousAlert = true
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
        .alert("Number not allowed", isPresented: $showAnonymousAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(Self.anonymousMessage)
        }
        .animation(.easeInOut(duration: 0.2), value: isAnonymousNumber)
    }

    // MARK: - Fields

    private var countrySelector: some View {
        Button {
            Haptics.selection()
            showCountryPicker = true
        } label: {
            HStack(spacing: 10) {
                Text(selectedCountry.flag)
                    .font(.title2)
                Text(selectedCountry.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Spacer()
                Text(selectedCountry.callingCode)
                    .font(.body)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(fieldBackground)
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Country: \(selectedCountry.name), calling code \(selectedCountry.callingCode)")
    }

    private var codeField: some View {
        TextField("+380", text: $codeText)
            .keyboardType(.phonePad)
            .font(.body.weight(.medium))
            .focused($focusedField, equals: .code)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(fieldBackground)
            .accessibilityLabel("Country calling code")
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
