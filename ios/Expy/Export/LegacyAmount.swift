import Foundation

/// Reads paise from a version 2 key, or converts the version 1 rupee keys.
enum LegacyAmount {
    static func paise<K: CodingKey>(_ c: KeyedDecodingContainer<K>, paise: K, rupees: [K]) throws -> Int {
        if let p = try c.decodeIfPresent(Int.self, forKey: paise) { return p }
        for key in rupees {
            if let r = try c.decodeIfPresent(Double.self, forKey: key) { return Money.paise(r) }
        }
        throw DecodingError.keyNotFound(paise, .init(codingPath: c.codingPath, debugDescription: "No amount"))
    }
}
