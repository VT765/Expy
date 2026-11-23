import SwiftData
import SwiftUI
import UniformTypeIdentifiers

enum AccountTarget: Identifiable {
    case new, existing(Account)
    var id: String { if case .existing(let a) = self { return a.id }; return "new" }
    var account: Account? { if case .existing(let a) = self { return a }; return nil }
}
