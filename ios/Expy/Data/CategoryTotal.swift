import Foundation

struct CategoryTotal: Identifiable {
    let categoryId: String
    let total: Double
    let pct: Double
    var id: String { categoryId }
}
