import AppIntents
import SwiftData

/// Bank accounts and cash exposed to Shortcuts/Siri.
struct AccountEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Account"
    static var defaultQuery = AccountQuery()
    let id: String
    let name: String
    let isCash: Bool
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", image: .init(systemName: isCash ? "banknote" : "building.columns"))
    }
}
