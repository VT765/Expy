import SwiftUI

/// Shared capsule styling for toasts.
struct ToastPillStyle: ViewModifier {
    let isError: Bool
    let trailingPadding: Double

    func body(content: Content) -> some View {
        content
            .foregroundStyle(isError ? .white : .black)
            .padding(.leading, 16).padding(.trailing, trailingPadding).padding(.vertical, 10)
            .background(Capsule().fill(isError ? Theme.danger : .white))
            .shadow(color: .black.opacity(0.5), radius: 16, y: 6)
    }
}
