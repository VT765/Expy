import Foundation
import Network
import Observation

/// Offline-first sync: push the outbox, then pull everything changed since the
/// last server cursor. Runs on launch, reconnect, foreground, after writes,
/// and every 5 minutes while active.
@MainActor
@Observable
final class SyncEngine {
    static let shared = SyncEngine()

    enum State { case local, offline, syncing, pending, error, synced }

    var isOnline = true
    var isSyncing = false
    var lastError: String?
    var pendingCount = 0
    var lastSyncedAt: Date? = UserDefaults.standard.object(forKey: "lastSyncedAt") as? Date

    private var cursor: Int64 {
        get { Int64(UserDefaults.standard.integer(forKey: "syncCursor")) }
        set { UserDefaults.standard.set(Int(newValue), forKey: "syncCursor") }
    }
    private var debounce: Task<Void, Never>?
    private var timer: Timer?
    private var rerun = false
    private let monitor = NWPathMonitor()

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self else { return }
                let was = self.isOnline
                self.isOnline = path.status == .satisfied
                if self.isOnline && !was { self.sync() }
            }
        }
        monitor.start(queue: DispatchQueue(label: "expy.network"))
    }

    var state: State {
        if APIClient.shared.token == nil { return .local }
        if !isOnline { return .offline }
        if isSyncing { return .syncing }
        if lastError != nil { return .error }
        if pendingCount > 0 { return .pending }
        return .synced
    }

    var label: String {
        switch state {
        case .local: "Local only"
        case .offline: pendingCount > 0 ? "Offline · \(pendingCount) pending" : "Offline"
        case .syncing: "Syncing…"
        case .error: "Sync failed"
        case .pending: "\(pendingCount) pending"
        case .synced: "Synced"
        }
    }

    func start() {
        refreshPending()
        sync()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task { @MainActor in SyncEngine.shared.sync() }
        }
    }

    func scheduleSync() {
        refreshPending()
        debounce?.cancel()
        debounce = Task {
            try? await Task.sleep(for: .milliseconds(800))
            if !Task.isCancelled { sync() }
        }
    }

    func refreshPending() {
        pendingCount = DataStore.shared.fetch(OutboxItem.self).count
    }

    @discardableResult
    func sync() -> Task<Void, Never> {
        Task { await run() }
    }

    func run() async {
        guard APIClient.shared.token != nil, isOnline else { return }
        if isSyncing { rerun = true; return }
        isSyncing = true
        defer {
            isSyncing = false
            refreshPending()
            if rerun { rerun = false; sync() }
        }
        do {
            try await push()
            let r: PullResponse = try await APIClient.shared.request("sync?since=\(cursor)")
            DataStore.shared.applyRemote(r)
            cursor = r.serverTime
            lastSyncedAt = Date()
            UserDefaults.standard.set(lastSyncedAt, forKey: "lastSyncedAt")
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private struct PushBody: Encodable { let changes: [String: [RawJSON]] }
    private struct PushResult: Decodable {}

    private func push() async throws {
        let store = DataStore.shared
        var items = store.fetch(OutboxItem.self)
        while !items.isEmpty {
            let batch = Array(items.prefix(500))
            var changes: [String: [RawJSON]] = [:]
            for i in batch { changes[i.collection, default: []].append(RawJSON(data: i.payload)) }
            let snapshot = batch.map { ($0.key, $0.updatedAt) }
            let _: [String: PushCollectionResult] = try await APIClient.shared.request("sync", method: "POST", body: PushBody(changes: changes))
            // Drop acked items unless they were edited again mid-flight.
            for (key, updatedAt) in snapshot {
                if let item = store.fetch(OutboxItem.self, #Predicate { $0.key == key }).first, item.updatedAt == updatedAt {
                    store.context.delete(item)
                }
            }
            store.save()
            items = Array(items.dropFirst(500))
        }
    }

    /// Best-effort push before sign-out. Returns true if nothing is left pending.
    func flush(timeout: Double = 6) async -> Bool {
        refreshPending()
        if pendingCount == 0 { return true }
        await withTaskGroup(of: Void.self) { g in
            g.addTask { await self.run() }
            g.addTask { try? await Task.sleep(for: .seconds(timeout)) }
            await g.next()
            g.cancelAll()
        }
        refreshPending()
        return pendingCount == 0
    }

    func resetCursor() {
        cursor = 0
        lastSyncedAt = nil
        lastError = nil
        UserDefaults.standard.removeObject(forKey: "lastSyncedAt")
    }
}

struct PushCollectionResult: Decodable {
    let applied: Int?
    let stale: Int?
}
