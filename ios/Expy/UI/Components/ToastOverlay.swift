import SwiftUI

/// Pill dropped in from under the status bar. Tap or swipe up to dismiss.
struct ToastOverlay: View {
    @State private var center = ToastCenter.shared

    var body: some View {
        VStack {
            if let t = center.current {
                ToastPill(toast: t, dismiss: center.hide)
                    .padding(.horizontal, Theme.gutter)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .gesture(DragGesture().onEnded { if $0.translation.height < -10 { center.hide() } })
                    .id(t.id)
            }
            Spacer()
        }
        .padding(.top, 4)
    }
}
