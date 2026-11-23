import AppIntents
import SwiftData

enum EntryKind: String, AppEnum {
    case debit, credit
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Type"
    static var caseDisplayRepresentations: [EntryKind: DisplayRepresentation] = [
        .debit: DisplayRepresentation(title: "Debit", subtitle: "Money spent", image: .init(systemName: "arrow.up.right")),
        .credit: DisplayRepresentation(title: "Credit", subtitle: "Money received", image: .init(systemName: "arrow.down.left")),
    ]
}
