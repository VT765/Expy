import Foundation

/// Amounts are stored as whole paise so totals never drift; views work in
/// rupees as Double and convert at the edges.
enum Money {
    static func paise(_ rupees: Double) -> Int { Int((rupees * 100).rounded()) }
    static func rupees(_ paise: Int) -> Double { Double(paise) / 100 }
}
