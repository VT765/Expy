import Foundation

/// Live rates from Frankfurter, cached for 12h as "units of base per 1 X".
@MainActor
final class RatesService {
    static let shared = RatesService()
    private let maxAge: TimeInterval = 12 * 3600

    private struct Cache: Codable { var base: String; var perUnit: [String: Double]; var fetchedAt: Date }
    private var cache: Cache? {
        didSet { if let cache, let d = try? JSONEncoder().encode(cache) { UserDefaults.standard.set(d, forKey: "rates") } }
    }

    private init() {
        if let d = UserDefaults.standard.data(forKey: "rates") { cache = try? JSONDecoder().decode(Cache.self, from: d) }
    }

    var fetchedAt: Date? { cache?.fetchedAt }

    func rate(_ currency: String, base: String) -> Double? {
        guard let cache, cache.base == base else { return nil }
        return cache.perUnit[currency]
    }

    private struct Response: Decodable { let rates: [String: Double] }

    func refresh(base: String, force: Bool = false) async throws {
        if !force, let cache, cache.base == base, Date().timeIntervalSince(cache.fetchedAt) < maxAge { return }
        let url = URL(string: "https://api.frankfurter.dev/v1/latest?base=\(base)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let r = try JSONDecoder().decode(Response.self, from: data)
        cache = Cache(base: base, perUnit: r.rates.compactMapValues { $0 > 0 ? 1 / $0 : nil }, fetchedAt: Date())
    }
}
