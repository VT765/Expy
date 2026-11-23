import Foundation

/// Picks the Expy account a bank message is about: the account last
/// confirmed for those digits, else a bank account whose name mentions the
/// bank, else the only bank account.
@MainActor
enum BankAccountMatcher {
    private static let key = "bankMessageDigits"

    static func account(last4: String?, bank: String?, among accounts: [Account], defaults: UserDefaults = .standard) -> Account? {
        let banks = accounts.filter { !$0.isCash }
        if let last4, let id = (defaults.dictionary(forKey: key) as? [String: String])?[last4],
           let a = accounts.first(where: { $0.id == id }) { return a }
        if let bank {
            let words = aliases(bank)
            if let a = banks.first(where: { a in words.contains { a.name.lowercased().contains($0) } }) { return a }
        }
        return banks.count == 1 ? banks.first : nil
    }

    /// Remembers "6821 → HDFC Bank" once the user confirms a suggestion.
    static func remember(last4: String?, accountId: String?, defaults: UserDefaults = .standard) {
        guard let last4, let accountId else { return }
        var map = defaults.dictionary(forKey: key) as? [String: String] ?? [:]
        map[last4] = accountId
        defaults.set(map, forKey: key)
    }

    private static func aliases(_ bank: String) -> [String] {
        switch bank {
        case "BoB": ["bob", "baroda"]
        case "SBI": ["sbi", "state bank"]
        default: [bank.lowercased()]
        }
    }
}
