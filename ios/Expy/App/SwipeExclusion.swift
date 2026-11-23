import SwiftUI

/// Registers this view's on-screen frame so a horizontal drag that starts
/// inside it scrolls it instead of changing page.
struct SwipeExclusion: ViewModifier {
    @Environment(\.swipeExclusionZones) private var zones
    @Environment(\.pageTab) private var tab
    @State private var id = UUID()

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }, action: update)
            .onDisappear(perform: remove)
    }

    private func update(_ frame: CGRect) {
        guard let tab else { return }
        zones?.set(id, tab: tab, frame: frame)
    }

    private func remove() { zones?.remove(id) }
}

extension View {
    /// Keeps this view's own horizontal scrolling or dragging; page swipes start elsewhere.
    func excludedFromPageSwipe() -> some View { modifier(SwipeExclusion()) }
}
