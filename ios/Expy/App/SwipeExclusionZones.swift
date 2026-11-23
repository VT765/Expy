import SwiftUI

/// Screen areas whose own horizontal drags win over page swiping: chip rows,
/// balance cards and charts. Not observable on purpose: frames update while
/// scrolling, and only the swipe gesture reads them.
@MainActor
final class SwipeExclusionZones {
    private var zones: [UUID: (tab: AppTab, frame: CGRect)] = [:]

    func set(_ id: UUID, tab: AppTab, frame: CGRect) { zones[id] = (tab, frame) }
    func remove(_ id: UUID) { zones[id] = nil }

    func contains(_ point: CGPoint, on tab: AppTab) -> Bool {
        zones.values.contains { $0.tab == tab && $0.frame.contains(point) }
    }
}

extension EnvironmentValues {
    @Entry var swipeExclusionZones: SwipeExclusionZones?
    /// The page a view belongs to; set by `pageSwipe(_:)`.
    @Entry var pageTab: AppTab?
}
