import AppIntents
import SwiftData

struct AccountQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [AccountEntity] {
        try await suggestedEntities().filter { identifiers.contains($0.id) }
    }

    @MainActor
    func suggestedEntities() async throws -> [AccountEntity] {
        DataStore.shared.activeAccounts.map { .init(id: $0.id, name: $0.name, isCash: $0.isCash) }
    }
}
