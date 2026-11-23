import Foundation

/// Prefill payload from URLs (expy://add?amount=&cat=&type=&note=).
struct Prefill {
    var amount: Double?
    var category: String?
    var kind: TransactionKind?
    var note: String?
    @MainActor static var pending: Prefill?

    init?(url: URL) {
        guard let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems, !items.isEmpty else { return nil }
        func q(_ k: String) -> String? { items.first { $0.name == k }?.value }
        amount = q("amount").flatMap(Double.init)
        category = q("cat")
        kind = q("type").map { $0.lowercased().hasPrefix("c") ? .credit : .expense }
        note = q("note")
    }
}

extension Notification.Name {
    static let prefillEntry = Notification.Name("expy.prefillEntry")
}
