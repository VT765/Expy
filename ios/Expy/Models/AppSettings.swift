import Foundation
import SwiftData

typealias AppSettings = SchemaV4.AppSettings

extension SchemaV4 {
    @Model
    final class AppSettings {
        @Attribute(.unique) var id: String // always "app"
        var cycleStartDay: Int
        var updatedAt: Date

        init(id: String = "app", cycleStartDay: Int = 1, updatedAt: Date = .distantPast) {
            self.id = id
            self.cycleStartDay = cycleStartDay
            self.updatedAt = updatedAt
        }
    }
}
