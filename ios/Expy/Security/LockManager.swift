import CommonCrypto
import Foundation
import LocalAuthentication
import Observation

/// App Lock: 4-digit PIN stored only as a salted PBKDF2-SHA256 hash in the
/// Keychain, Face ID via LocalAuthentication, auto-lock on background.
@MainActor
@Observable
final class LockManager {
    static let shared = LockManager()

    enum AutoLock: String, CaseIterable, Identifiable {
        case immediate, oneMinute, fiveMinutes
        var id: String { rawValue }
        var seconds: TimeInterval { [.immediate: 0, .oneMinute: 60, .fiveMinutes: 300][self]! }
        var label: String { [.immediate: "Immediately", .oneMinute: "After 1 minute", .fiveMinutes: "After 5 minutes"][self]! }
    }

    private static let iterations: UInt32 = 210_000
    private static let maxAttempts = 5
    private static let cooldown: TimeInterval = 30

    private(set) var enabled: Bool
    private(set) var faceIdEnabled: Bool
    var autoLock: AutoLock { didSet { UserDefaults.standard.set(autoLock.rawValue, forKey: "autoLock") } }
    var isLocked: Bool
    private(set) var failures: Int { didSet { UserDefaults.standard.set(failures, forKey: "pinFailures") } }
    private(set) var cooldownUntil: Date? { didSet { UserDefaults.standard.set(cooldownUntil, forKey: "pinCooldown") } }
    private var backgroundedAt: Date?

    private init() {
        let hasPin = Keychain.data(for: "pinHash") != nil
        enabled = hasPin
        faceIdEnabled = hasPin && UserDefaults.standard.bool(forKey: "faceId")
        autoLock = AutoLock(rawValue: UserDefaults.standard.string(forKey: "autoLock") ?? "") ?? .immediate
        failures = UserDefaults.standard.integer(forKey: "pinFailures")
        cooldownUntil = UserDefaults.standard.object(forKey: "pinCooldown") as? Date
        isLocked = hasPin // always start locked when a PIN is set
    }

    // MARK: PIN

    private static func derive(_ pin: String, salt: Data, iterations: UInt32) -> Data {
        var out = Data(count: 32)
        let pinData = Array(pin.utf8)
        _ = out.withUnsafeMutableBytes { outPtr in
            salt.withUnsafeBytes { saltPtr in
                CCKeyDerivationPBKDF(CCPBKDFAlgorithm(kCCPBKDF2),
                                     pinData.map { Int8(bitPattern: $0) }, pinData.count,
                                     saltPtr.bindMemory(to: UInt8.self).baseAddress, salt.count,
                                     CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), iterations,
                                     outPtr.bindMemory(to: UInt8.self).baseAddress, 32)
            }
        }
        return out
    }

    func setPin(_ pin: String) {
        var salt = Data(count: 16)
        _ = salt.withUnsafeMutableBytes { SecRandomCopyBytes(kSecRandomDefault, 16, $0.baseAddress!) }
        Keychain.set(Self.derive(pin, salt: salt, iterations: Self.iterations), for: "pinHash")
        Keychain.set(salt, for: "pinSalt")
        enabled = true
        failures = 0
        cooldownUntil = nil
    }

    func checkPin(_ pin: String) -> Bool {
        guard let hash = Keychain.data(for: "pinHash"), let salt = Keychain.data(for: "pinSalt") else { return false }
        let candidate = Self.derive(pin, salt: salt, iterations: Self.iterations)
        guard candidate.count == hash.count else { return false }
        return zip(candidate, hash).reduce(0) { $0 | ($1.0 ^ $1.1) } == 0 // constant time
    }

    enum Attempt { case ok, wrong, cooldown }

    func attempt(_ pin: String) -> Attempt {
        if let until = cooldownUntil, until > Date() { return .cooldown }
        if checkPin(pin) {
            failures = 0
            cooldownUntil = nil
            isLocked = false
            return .ok
        }
        failures += 1
        if failures >= Self.maxAttempts {
            failures = 0
            cooldownUntil = Date().addingTimeInterval(Self.cooldown)
            return .cooldown
        }
        return .wrong
    }

    var attemptsLeft: Int { Self.maxAttempts - failures }

    func disable() {
        Keychain.set(nil as Data?, for: "pinHash")
        Keychain.set(nil as Data?, for: "pinSalt")
        UserDefaults.standard.set(false, forKey: "faceId")
        enabled = false
        faceIdEnabled = false
        isLocked = false
        failures = 0
        cooldownUntil = nil
    }

    // MARK: Face ID

    var biometryAvailable: Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    var biometryName: String {
        let ctx = LAContext()
        _ = ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return ctx.biometryType == .touchID ? "Touch ID" : "Face ID"
    }

    func setFaceId(_ on: Bool) async -> Bool {
        if on {
            guard await authenticateBiometric(reason: "Turn on \(biometryName) for Expy") else { return false }
        }
        faceIdEnabled = on
        UserDefaults.standard.set(on, forKey: "faceId")
        return true
    }

    func authenticateBiometric(reason: String = "Unlock Expy") async -> Bool {
        let ctx = LAContext()
        ctx.localizedFallbackTitle = "Use PIN"
        do {
            return try await ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch {
            return false
        }
    }

    func unlockWithBiometrics() async {
        guard faceIdEnabled, isLocked else { return }
        if await authenticateBiometric() { isLocked = false; failures = 0 }
    }

    // MARK: Lifecycle

    func didEnterBackground() { backgroundedAt = Date() }

    func willEnterForeground() {
        defer { backgroundedAt = nil }
        guard enabled, let t = backgroundedAt else { return }
        if Date().timeIntervalSince(t) >= autoLock.seconds { isLocked = true }
    }
}
