import Observation
import SwiftUI

/// Selected tab, shared so any screen can jump to another (e.g. Settings).
/// `direction` tells the incoming page which side to slide in from.
@MainActor
@Observable
final class AppRouter {
    var tab = AppTab.tap {
        didSet { direction = tab.rawValue >= oldValue.rawValue ? 1 : -1 }
    }
    /// 1 = moved right in tab order (slide in from the trailing edge), -1 = left.
    private(set) var direction = 1

    init() {
        #if DEBUG
        if let raw = Demo.value("-startTab").flatMap(Int.init), let t = AppTab(rawValue: raw) { tab = t }
        #endif
    }

    func showSettings() { tab = .settings }

    /// The neighbouring tab in swipe order, if any.
    func neighbour(of tab: AppTab, by step: Int) -> AppTab? { AppTab(rawValue: tab.rawValue + step) }
}

extension EnvironmentValues {
    @Entry var appRouter: AppRouter?
}
