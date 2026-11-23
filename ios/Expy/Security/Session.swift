import Foundation
import Observation

/// Signed-in / local-only state and sign-out.
@MainActor
@Observable
final class Session {
    static let shared = Session()

    var isSignedIn: Bool
    var offlineMode: Bool { didSet { UserDefaults.standard.set(offlineMode, forKey: "offlineMode") } }
    var needsLogin: Bool { !isSignedIn && !offlineMode }

    private init() {
        isSignedIn = APIClient.shared.token != nil
        offlineMode = UserDefaults.standard.bool(forKey: "offlineMode")
    }

    func signedIn(token: String) {
        APIClient.shared.token = token
        isSignedIn = true
        offlineMode = false
        SyncEngine.shared.resetCursor()
        SyncEngine.shared.sync()
    }

    /// 401 from the server: keep local data and the outbox, ask to sign in again.
    func tokenDropped() { isSignedIn = false }

    /// Clears this device: data, sync state, App Lock.
    func wipeDevice() {
        APIClient.shared.token = nil
        isSignedIn = false
        offlineMode = false
        SyncEngine.shared.resetCursor()
        DataStore.shared.resetLocal()
        SyncEngine.shared.refreshPending()
        LockManager.shared.disable()
    }

    /// Pushes pending changes first. Returns false if some couldn't be synced.
    func signOutFlushing() async -> Bool {
        let flushed = await SyncEngine.shared.flush()
        if flushed { wipeDevice() }
        return flushed
    }
}
