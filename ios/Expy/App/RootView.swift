import SwiftUI

/// Tabs (History · Tap · Analytics · Settings) in the system tab bar, each
/// swipeable to its neighbours, behind the lock screen, plus the toast
/// overlay, haptics player and app-switcher privacy cover.
struct RootView: View {
    @State private var lock = LockManager.shared
    @State private var haptics = HapticFeedback.shared
    @State private var router = AppRouter()
    @State private var swipeZones = SwipeExclusionZones()
    @State private var inbox = ReviewInbox.shared
    /// Cold launch only; UI tests and debug screenshots pass -noSplash.
    @State private var showSplash = !ProcessInfo.processInfo.arguments.contains("-noSplash") && DebugScreen.requested == nil
    @Environment(\.scenePhase) private var phase

    var body: some View {
        ZStack {
            if let solo = DebugScreen.requested {
                DebugScreen(screen: solo)
            } else if !lock.isLocked {
                TabView(selection: $router.tab) {
                    HistoryView().pageSwipe(.history)
                        .tabItem { Label(AppTab.history.title, systemImage: AppTab.history.icon) }.tag(AppTab.history)
                        .badge(inbox.count)
                    TapView().pageSwipe(.tap)
                        .tabItem { Label(AppTab.tap.title, systemImage: AppTab.tap.icon) }.tag(AppTab.tap)
                    AnalyticsView().pageSwipe(.analytics)
                        .tabItem { Label(AppTab.analytics.title, systemImage: AppTab.analytics.icon) }.tag(AppTab.analytics)
                    SettingsView().pageSwipe(.settings)
                        .tabItem { Label(AppTab.settings.title, systemImage: AppTab.settings.icon) }.tag(AppTab.settings)
                }
                .toolbarBackground(Theme.card, for: .tabBar)
                .toolbarBackground(.visible, for: .tabBar)
                .environment(\.appRouter, router)
                .environment(\.swipeExclusionZones, swipeZones)
                .onChange(of: router.tab) { Haptics.selection() }
                .onReceive(NotificationCenter.default.publisher(for: .openReviewInbox)) { _ in router.tab = .history }
            }
            if lock.isLocked { LockView().transition(.opacity) }
            // Privacy cover for the app switcher snapshot.
            Theme.canvas.ignoresSafeArea()
                .opacity(phase != .active && lock.enabled ? 1 : 0)
                .allowsHitTesting(false)
            ToastOverlay()
            if showSplash {
                SplashView(finish: hideSplash).zIndex(1)
            }
        }
        .animation(.easeOut(duration: 0.2), value: lock.isLocked)
        .sensoryFeedback(trigger: haptics.tick) { _, _ in haptics.pending }
    }

    private func hideSplash() { showSplash = false }
}
