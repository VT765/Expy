import SwiftData
import SwiftUI
import UserNotifications

@main
struct ExpyApp: App {
    @Environment(\.scenePhase) private var phase

    init() {
        _ = DataStore.shared // seeds defaults
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-seedDemo") { DataStore.shared.seedDemo() }
        if ProcessInfo.processInfo.arguments.contains("-demoInbox") { DataStore.shared.seedDemoInbox() }
        #endif
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(.white)
                .onOpenURL(perform: open)
        }
        .modelContainer(Persistence.container)
        .onChange(of: phase) { _, newPhase in phaseChanged(newPhase) }
    }

    /// expy://add?amount=80&cat=Food&type=expense&note=Chai
    private func open(_ url: URL) {
        guard let p = Prefill(url: url) else { return }
        Prefill.pending = p
        NotificationCenter.default.post(name: .prefillEntry, object: p)
    }

    private func phaseChanged(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            LockManager.shared.didEnterBackground()
            DataStore.shared.save()
        case .active:
            LockManager.shared.willEnterForeground()
            RecurringEngine.processDue()
        default:
            break
        }
    }
}
