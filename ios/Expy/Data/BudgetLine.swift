import Foundation

struct BudgetLine: Identifiable {
    let id: String
    let categoryId: String?
    let amount: Double
    let spent: Double
    var remaining: Double { amount - spent }
    var pct: Double { amount > 0 ? spent / amount : 0 }
    var over: Bool { remaining < 0 }
    let perDay: Double
}
