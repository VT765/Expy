import Observation
import SwiftUI

/// App-wide toast queue (one visible at a time).
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
