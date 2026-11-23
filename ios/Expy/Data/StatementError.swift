import Foundation

struct StatementError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
