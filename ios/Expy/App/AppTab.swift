/// Bottom bar tabs, in swipe order.
enum AppTab: Int, CaseIterable, Hashable {
    case history, tap, analytics, settings

    var title: String {
        switch self {
        case .history: "History"
        case .tap: "Tap"
        case .analytics: "Analytics"
        case .settings: "Settings"
        }
    }

    var icon: String {
        switch self {
        case .history: "list.bullet"
        case .tap: "scope"
        case .analytics: "chart.line.uptrend.xyaxis"
        case .settings: "gearshape"
        }
    }
}
