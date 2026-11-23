import SwiftData
import SwiftUI

@main
struct ExpyApp: App {
    @Environment(\.scenePhase) private var phase

    init() {
        _ = DataStore.shared // seeds defaults
        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(Theme.card)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = .black
        nav.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .tint(.white)
                .onOpenURL { url in
                    // expy://add?amount=80&cat=Food&type=expense&note=Chai
                    if let p = Prefill(url: url) {
                        Prefill.pending = p
                        NotificationCenter.default.post(name: .prefillEntry, object: p)
                    }
                }
        }
        .modelContainer(Persistence.container)
        .onChange(of: phase) { _, p in
            switch p {
            case .background:
                LockManager.shared.didEnterBackground()
                DataStore.shared.save()
            case .active:
                LockManager.shared.willEnterForeground()
                Task { try? await RatesService.shared.refresh(base: DataStore.shared.settings.baseCurrency) }
                SyncEngine.shared.sync()
            default: break
            }
        }
    }
}

struct RootView: View {
    @State private var lock = LockManager.shared
    @State private var session = Session.shared
    @State private var tab = Tab.tap
    @State private var showSettings = false
    @Environment(\.scenePhase) private var phase

    enum Tab { case history, tap, analytics }

    var body: some View {
        ZStack {
            if !session.needsLogin && !lock.isLocked {
                TabView(selection: $tab) {
                    HistoryView().tabItem { Label("History", systemImage: "list.bullet") }.tag(Tab.history)
                    TapView().tabItem { Label("Tap", systemImage: "scope") }.tag(Tab.tap)
                    AnalyticsView().tabItem { Label("Analytics", systemImage: "chart.line.uptrend.xyaxis") }.tag(Tab.analytics)
                }
                .environment(\.showSettings, ShowSettingsAction { showSettings = true })
                .sheet(isPresented: $showSettings) { SettingsView() }
                .onChange(of: tab) { Haptics.selection() }
            }
            if session.needsLogin && !lock.isLocked { LoginView().transition(.opacity) }
            if lock.isLocked { LockView().transition(.opacity) }
            // Privacy cover for the app switcher snapshot.
            if phase != .active && lock.enabled { Theme.canvas.ignoresSafeArea() }
            ToastOverlay()
        }
        .animation(.easeOut(duration: 0.2), value: lock.isLocked)
        .animation(.easeOut(duration: 0.2), value: session.needsLogin)
        .task { SyncEngine.shared.start() }
    }
}
