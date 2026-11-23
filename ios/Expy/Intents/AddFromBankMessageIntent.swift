import AppIntents
import Foundation

/// The action a Shortcuts automation runs on each bank SMS or email: reads
/// the text and adds an entry to review (or logs it, if auto-log is on).
/// Messages that aren't transactions are ignored quietly.
struct AddFromBankMessageIntent: AppIntent {
    static var title: LocalizedStringResource = "Add from Bank Message"
    static var description = IntentDescription("Reads a bank SMS or email and suggests the transaction in Expy for one-tap review.")
    static var openAppWhenRun = false

    @Parameter(title: "Message", inputOptions: String.IntentInputOptions(multiline: true)) var message: String

    static var parameterSummary: some ParameterSummary { Summary("Add \(\.$message) to Expy") }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        guard let parsed = BankMessageParser.parse(message) else {
            return .result(value: "", dialog: "Not a bank transaction, nothing added.")
        }
        let inbox = ReviewInbox.shared
        guard let s = inbox.suggestion(from: parsed) else {
            return .result(value: "", dialog: "Already in Expy.")
        }
        let what = "\(s.kind == .credit ? "+" : "")\(Fmt.money(s.amount))\(s.note.isEmpty ? "" : (s.kind == .credit ? " from " : " to ") + s.note)"
        if UserDefaults.standard.bool(forKey: ReviewInbox.autoLogKey) && !s.possibleDuplicate && s.accountId != nil {
            inbox.accept(s)
            return .result(value: what, dialog: "Logged \(what)")
        }
        inbox.add(s)
        Notifier.post(id: "review-\(s.id.uuidString)", title: "Review in Expy", body: "\(what). Tap to add it.")
        return .result(value: what, dialog: "Added \(what) to review")
    }
}
