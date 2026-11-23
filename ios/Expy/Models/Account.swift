import Foundation
import SwiftData

typealias Account = SchemaV4.Account

extension SchemaV4 {
    /// A bank account or cash wallet. Balance = opening balance (as of
    /// `openingDate`) plus the effect of every entry dated on or after it.
    @Model
    final class Account {
        @Attribute(.unique) var id: String
        var name: String
        @Attribute(originalName: "kind") var kindRaw: String
        var openingBalancePaise: Int
        var openingDate: Date
        var order: Int
        var updatedAt: Date
        var deletedAt: Date?

        init(id: String = "acc_\(UUID().uuidString.lowercased())", name: String, kind: AccountKind, openingBalancePaise: Int,
             openingDate: Date, order: Int, updatedAt: Date = .now) {
            self.id = id
            self.name = name
            self.kindRaw = kind.rawValue
            self.openingBalancePaise = openingBalancePaise
            self.openingDate = openingDate
            self.order = order
            self.updatedAt = updatedAt
        }

        var kind: AccountKind {
            get { AccountKind(rawValue: kindRaw) ?? .bank }
            set { kindRaw = newValue.rawValue }
        }

        /// Rupees.
        var openingBalance: Double {
            get { Money.rupees(openingBalancePaise) }
            set { openingBalancePaise = Money.paise(newValue) }
        }

        var isCash: Bool { kind == .cash }
        var symbol: String { isCash ? "banknote" : "building.columns" }
    }
}
