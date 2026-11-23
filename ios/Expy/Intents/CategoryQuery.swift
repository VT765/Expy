import AppIntents
import SwiftData

struct CategoryQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [CategoryEntity] {
        try await suggestedEntities().filter { identifiers.contains($0.id) }
    }

    @MainActor
    func suggestedEntities() async throws -> [CategoryEntity] {
        DataStore.shared.activeCategories.map { .init(id: $0.id, name: $0.name, emoji: $0.emoji) }
    }

    /// Categories for one kind, for the Shortcut's "Choose a category" step.
    @MainActor
    func entities(for kind: TransactionKind) -> [CategoryEntity] {
        DataStore.shared.categories(kind).map { .init(id: $0.id, name: $0.name, emoji: $0.emoji) }
    }
}
