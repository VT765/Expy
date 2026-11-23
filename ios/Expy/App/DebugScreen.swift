import SwiftUI

/// Debug builds: `-solo history|analytics|settings` renders one screen alone
/// for simulator screenshots. Always nil in release builds.
struct DebugScreen: View {
    enum Screen: String { case history, analytics, settings }
    let screen: Screen

    static var requested: Screen? {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-solo"), i + 1 < args.count else { return nil }
        return Screen(rawValue: args[i + 1])
        #else
        return nil
        #endif
    }

    var body: some View {
        switch screen {
        case .history: HistoryView()
        case .analytics: AnalyticsView()
        case .settings: SettingsView()
        }
    }
}
