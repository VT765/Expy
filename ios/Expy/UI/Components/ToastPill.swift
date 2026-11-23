import SwiftUI

/// The toast itself: a dismiss button, or a message with an action (Undo).
struct ToastPill: View {
    let toast: ToastCenter.Toast
    let dismiss: () -> Void

    var body: some View {
        if let label = toast.actionLabel {
            HStack(spacing: 8) {
                Text(toast.message).font(.app(14, .semibold)).lineLimit(2)
                Button(label, action: runAction)
                    .font(.app(14, .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14).frame(minHeight: 32)
                    .background(Capsule().fill(.black))
                    .frame(minHeight: 44)
                    .contentShape(.capsule)
            }
            .modifier(ToastPillStyle(isError: toast.isError, trailingPadding: 6))
        } else {
            Button(action: dismiss) {
                Label {
                    Text(toast.message).font(.app(14, .semibold)).lineLimit(2)
                } icon: {
                    Image(systemName: toast.isError ? "exclamationmark.triangle.fill" : "checkmark")
                        .font(.app(13, .bold))
                }
                .modifier(ToastPillStyle(isError: toast.isError, trailingPadding: 16))
            }
            .buttonStyle(.plain)
            .accessibilityHint("Dismisses the message")
        }
    }

    private func runAction() {
        toast.action?()
        dismiss()
    }
}
