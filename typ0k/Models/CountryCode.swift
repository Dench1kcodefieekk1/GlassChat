import Foundation

struct CountryCode: Identifiable, Hashable {
    let callingCode: String
    let flag: String
    let name: String

    var id: String { callingCode }

    static let all: [CountryCode] = [
        CountryCode(callingCode: "+380", flag: "🇺🇦", name: "Ukraine"),
        CountryCode(callingCode: "+1", flag: "🇺🇸", name: "United States"),
        CountryCode(callingCode: "+44", flag: "🇬🇧", name: "United Kingdom"),
        CountryCode(callingCode: "+49", flag: "🇩🇪", name: "Germany"),
        CountryCode(callingCode: "+33", flag: "🇫🇷", name: "France"),
        CountryCode(callingCode: "+39", flag: "🇮🇹", name: "Italy"),
        CountryCode(callingCode: "+34", flag: "🇪🇸", name: "Spain"),
        CountryCode(callingCode: "+48", flag: "🇵🇱", name: "Poland"),
        CountryCode(callingCode: "+81", flag: "🇯🇵", name: "Japan"),
        CountryCode(callingCode: "+86", flag: "🇨🇳", name: "China"),
        CountryCode(callingCode: "+7", flag: "🇷🇺", name: "Russia & Kazakhstan"),
        CountryCode(callingCode: "+90", flag: "🇹🇷", name: "Turkey"),
        CountryCode(callingCode: "+971", flag: "🇦🇪", name: "United Arab Emirates"),
        CountryCode(callingCode: "+972", flag: "🇮🇱", name: "Israel")
    ]

    static let unknownFlag = "🌐"

    static func match(exact text: String) -> CountryCode? {
        let normalized = text.hasPrefix("+") ? text : "+" + text
        return all.first { $0.callingCode == normalized }
    }
}
