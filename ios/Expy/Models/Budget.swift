import Foundation
import SwiftData

typealias Budget = SchemaV4.Budget

extension SchemaV4 {
    @Model
    final class Budget {
        @Attribute(.unique) var id: String
        /// nil = overall monthly budget.
        var categoryId: String?
        var amountPaise: Int
        var updatedAt: Date
        var deletedAt: Date?

        init(id: String, categoryId: String?, amountPaise: Int, updatedAt: Date, deletedAt: Date? = nil) {
            self.id = id
            self.categoryId = categoryId
            self.amountPaise = amountPaise
            self.updatedAt = updatedAt
            self.deletedAt = deletedAt
        }

        /// Rupees.
        var amount: Double {
            get { Money.rupees(amountPaise) }
            set { amountPaise = Money.paise(newValue) }
        }
    }
}
