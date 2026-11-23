import AppIntents
import SwiftData

/// Categories exposed to Shortcuts/Siri.
struct CategoryEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static var defaultQuery = CategoryQuery()
    let id: String
    let name: String
    let emoji: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(emoji) \(name)") }
}
