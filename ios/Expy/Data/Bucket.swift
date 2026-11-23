import Foundation

struct Bucket: Identifiable {
    let start: Date
    let end: Date
    let short: String
    let long: String
    var total: Double = 0
    var id: Date { start }
}
