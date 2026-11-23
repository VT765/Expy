import SwiftUI
import Observation

@MainActor
@Observable
final class ToastCenter {
    static let shared = ToastCenter()

    struct Toast: Identifiable, Equatable {
        let id = UUID()
        let message: String
        var isError = false
        var actionLabel: String?
        var action: (() -> Void)?
        static func == (a: Toast, b: Toast) -> Bool { a.id == b.id }
    }

    var current: Toast?
    private var hideTask: Task<Void, Never>?

    func show(_ message: String, error: Bool = false, action: (label: String, run: () -> Void)? = nil, duration: Double? = nil) {
        let t = Toast(message: message, isError: error, actionLabel: action?.label, action: action?.run)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { current = t }
        if error { Haptics.error() }
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(duration ?? (action != nil ? 4.5 : 2.2)))
            if !Task.isCancelled, current?.id == t.id { hide() }
        }
    }

    func error(_ message: String) { show(message, error: true, duration: 3.5) }

    func hide() { withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) { current = nil } }
}

/// Pill dropped in from under the status bar. Tap/swipe up to dismiss.
struct ToastOverlay: View {
    @State private var center = ToastCenter.shared

    var body: some View {
        VStack {
            if let t = center.current {
                HStack(spacing: 8) {
                    if !t.isError && t.actionLabel == nil { Image(systemName: "checkmark").font(.system(size: 13, weight: .bold)) }
                    Text(t.message).font(.system(size: 14, weight: .semibold)).lineLimit(2)
                    if let label = t.actionLabel {
                        Button(label) {
                            t.action?()
                            center.hide()
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14).padding(.vertical, 6)
                        .background(Capsule().fill(.black))
                    }
                }
                .foregroundStyle(t.isError ? .white : .black)
                .padding(.leading, 16).padding(.trailing, t.actionLabel == nil ? 16 : 6).padding(.vertical, 10)
                .background(Capsule().fill(t.isError ? Theme.danger : .white))
                .shadow(color: .black.opacity(0.5), radius: 16, y: 6)
                .padding(.horizontal, Theme.gutter)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onTapGesture { if t.actionLabel == nil { center.hide() } }
                .gesture(DragGesture().onEnded { if $0.translation.height < -10 { center.hide() } })
                .id(t.id)
            }
            Spacer()
        }
        .padding(.top, 4)
    }
}

enum Haptics {
    static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    static func soft() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
}
