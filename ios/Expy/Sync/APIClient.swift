import Foundation

struct APIError: LocalizedError {
    let status: Int
    let message: String
    var errorDescription: String? { message }
}

/// Talks to the Vercel API (same endpoints as the PWA). The JWT lives in the Keychain.
@MainActor
final class APIClient {
    static let shared = APIClient()
    static let defaultServer = "https://expy-iota.vercel.app"

    var serverURL: String {
        get { UserDefaults.standard.string(forKey: "serverURL") ?? Self.defaultServer }
        set { UserDefaults.standard.set(newValue.trimmingCharacters(in: CharacterSet(charactersIn: "/ ")), forKey: "serverURL") }
    }

    var token: String? {
        get { Keychain.string(for: "jwt") }
        set { Keychain.set(newValue, for: "jwt") }
    }

    private let session: URLSession = {
        let c = URLSessionConfiguration.default
        c.timeoutIntervalForRequest = 15
        c.waitsForConnectivity = false
        return URLSession(configuration: c)
    }()

    func request<T: Decodable>(_ path: String, method: String = "GET", body: Encodable? = nil, auth: Bool = true, as: T.Type = T.self) async throws -> T {
        guard let url = URL(string: "\(serverURL)/api/\(path)") else { throw APIError(status: 0, message: "Invalid server URL") }
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let body {
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }
        if auth, let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError(status: 0, message: "Can't reach the server")
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? "Request failed (\(status))"
            if status == 401, auth, token != nil {
                token = nil
                Session.shared.tokenDropped()
            }
            throw APIError(status: status, message: msg)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

/// Lets `request` take any Encodable body.
struct AnyEncodable: Encodable {
    let value: Encodable
    init(_ value: Encodable) { self.value = value }
    func encode(to encoder: Encoder) throws { try value.encode(to: encoder) }
}

/// Raw JSON pass-through for outbox payloads (already-encoded documents).
struct RawJSON: Encodable {
    let data: Data
    func encode(to encoder: Encoder) throws {
        let obj = try JSONSerialization.jsonObject(with: data)
        try JSONValue(obj).encode(to: encoder)
    }
}

private struct JSONValue: Encodable {
    let v: Any
    init(_ v: Any) { self.v = v }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch v {
        case let n as NSNumber where CFGetTypeID(n) == CFBooleanGetTypeID(): try c.encode(n.boolValue)
        case let n as NSNumber:
            if CFNumberIsFloatType(n) { try c.encode(n.doubleValue) } else { try c.encode(n.int64Value) }
        case let s as String: try c.encode(s)
        case let a as [Any]: try c.encode(a.map(JSONValue.init))
        case let d as [String: Any]: try c.encode(d.mapValues(JSONValue.init))
        default: try c.encodeNil()
        }
    }
}
