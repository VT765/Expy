import SwiftUI

/// Swipe left/right on a tab's page to move to the neighbouring tab, while
/// keeping the system tab bar. The page tracks the finger 1:1 and fades,
/// carries on off-screen when released past the threshold, and the next
/// page glides in from the opposite side. Runs alongside vertical
/// scrolling; only clearly horizontal drags count.
struct PageSwipe: ViewModifier {
    let tab: AppTab
    @Environment(\.appRouter) private var router
    @Environment(\.swipeExclusionZones) private var zones
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var width = 390.0
    @State private var dragX = 0.0
    @State private var slideX = 0.0
    @State private var fade = 1.0
    @State private var dragIgnored = false
    @State private var leaving = false
    /// Resets to false when the system cancels the drag (no onEnded then).
    @GestureState private var isDragging = false

    /// A release changes page past this fraction of the width, or when flung
    /// faster than `flickSpeed` points per second (short quick swipes).
    private static let threshold = 0.18
    private static let flick = 0.3
    private static let flickSpeed = 300.0
    /// How far the incoming page starts from its resting place, as a fraction of the width.
    private static let entry = 0.3

    func body(content: Content) -> some View {
        content
            .environment(\.pageTab, tab)
            .compositingGroup()
            .offset(x: reduceMotion ? 0 : dragX + slideX)
            .opacity(reduceMotion ? 1 : fade * (1 - min(abs(dragX) / width, 1) * 0.45))
            .onGeometryChange(for: Double.self, of: { $0.size.width }, action: { width = max($0, 1) })
            .simultaneousGesture(swipe)
            .onChange(of: router?.tab) { _, new in if new == tab { slideIn() } }
            .onChange(of: isDragging) { _, dragging in if !dragging { settleIfCancelled() } }
    }

    private var swipe: some Gesture {
        DragGesture(minimumDistance: 16, coordinateSpace: .global)
            .updating($isDragging) { _, state, _ in state = true }
            .onChanged(changed)
            .onEnded(ended)
    }

    private func isHorizontal(_ t: CGSize) -> Bool { abs(t.width) > abs(t.height) * 1.6 }

    private func target(for dx: Double) -> AppTab? { router?.neighbour(of: tab, by: dx < 0 ? 1 : -1) }

    private func changed(_ v: DragGesture.Value) {
        guard !leaving else { return }
        if dragX == 0 && !dragIgnored {
            dragIgnored = zones?.contains(v.startLocation, on: tab) ?? false
        }
        guard !dragIgnored, isHorizontal(v.translation) else { return }
        let dx = v.translation.width
        // 1:1 towards a neighbour; rubber-band at the first and last page.
        dragX = target(for: dx) != nil ? dx : dx * 0.15
    }

    private func ended(_ v: DragGesture.Value) {
        defer { dragIgnored = false }
        let dx = v.translation.width
        let flung = abs(v.velocity.width) > Self.flickSpeed && (v.velocity.width < 0) == (dx < 0)
        guard !leaving, !dragIgnored, isHorizontal(v.translation),
              abs(dx) > width * Self.threshold || abs(v.predictedEndTranslation.width) > width * Self.flick || flung,
              let router, let next = target(for: dx) else {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) { dragX = 0 }
            return
        }
        guard !reduceMotion else {
            dragX = 0
            router.tab = next
            return
        }
        leaving = true
        // Finish the throw, then hand over to the next page.
        withAnimation(.easeOut(duration: 0.14)) {
            dragX = dx < 0 ? -width * 0.55 : width * 0.55
            fade = 0
        } completion: {
            router.tab = next
            dragX = 0
            fade = 1
            leaving = false
        }
    }

    /// A cancelled drag never reaches `ended`; don't leave the page shifted.
    private func settleIfCancelled() {
        dragIgnored = false
        guard !leaving, dragX != 0 else { return }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) { dragX = 0 }
    }

    private func slideIn() {
        guard !reduceMotion, let router else { return }
        var t = Transaction()
        t.disablesAnimations = true
        withTransaction(t) {
            slideX = Double(router.direction) * width * Self.entry
            fade = 0
        }
        withAnimation(.spring(response: 0.34, dampingFraction: 0.9)) {
            slideX = 0
            fade = 1
        }
    }
}

extension View {
    /// Makes this tab's page swipeable to its neighbours.
    func pageSwipe(_ tab: AppTab) -> some View { modifier(PageSwipe(tab: tab)) }
}
