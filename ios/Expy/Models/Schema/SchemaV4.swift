import Foundation
import SwiftData

/// Current store: V3 plus a kind on categories, so credits get their own
/// categories (Salary, Refund…). Models live in their own files as
/// `SchemaV4` extensions; the app uses them via typealiases.
enum SchemaV4: VersionedSchema {
    static let versionIdentifier = Schema.Version(4, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Entry.self, ExpenseCategory.self, Account.self, Budget.self, AppSettings.self, RecurringRule.self]
    }
}
