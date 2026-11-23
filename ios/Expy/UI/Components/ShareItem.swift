import Foundation

/// A file to present in the share sheet.
struct ShareItem: Identifiable {
    let url: URL
    var id: URL { url }
}
