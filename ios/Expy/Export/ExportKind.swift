import Foundation

enum ExportKind: String, Identifiable {
    case xlsx, csv, backup
    var id: String { rawValue }
}
