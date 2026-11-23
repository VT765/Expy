import Foundation
import SwiftData

/// V1 → V2 adds paise columns and fills them from the old Double amounts
/// (foreign-currency entries keep their original amount in the note).
/// V2 → V3 drops the old columns, renames type/kind, removes the outbox
/// and adds recurring rules. V3 → V4 gives categories a kind; existing ones
/// become expense categories and the default credit categories are seeded
/// on launch.
enum ExpyMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self] }
    static var stages: [MigrationStage] { [v1ToV2, v2ToV3, v3ToV4] }

    static let v1ToV2 = MigrationStage.custom(fromVersion: SchemaV1.self, toVersion: SchemaV2.self, willMigrate: nil) { context in
        for e in try context.fetch(FetchDescriptor<SchemaV2.Entry>()) {
            e.amountPaise = Money.paise(e.amountInBase)
            if e.currency != "INR", e.amount > 0 {
                let original = "\(e.currency) \(e.amount.formatted(.number.precision(.fractionLength(0...2))))"
                e.note = e.note.isEmpty ? original : "\(e.note) (\(original))"
            }
        }
        for a in try context.fetch(FetchDescriptor<SchemaV2.Account>()) { a.openingBalancePaise = Money.paise(a.openingBalance) }
        for b in try context.fetch(FetchDescriptor<SchemaV2.Budget>()) { b.amountPaise = Money.paise(b.amount) }
        try context.save()
    }

    static let v2ToV3 = MigrationStage.lightweight(fromVersion: SchemaV2.self, toVersion: SchemaV3.self)

    static let v3ToV4 = MigrationStage.lightweight(fromVersion: SchemaV3.self, toVersion: SchemaV4.self)
}
