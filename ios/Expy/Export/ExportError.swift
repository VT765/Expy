import Foundation

struct ExportError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}
