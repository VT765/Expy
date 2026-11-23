import SwiftUI

/// Rounded export button with a spinner while busy.
struct ExportButton: View {
    let title: String
    let busy: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                ZStack {
                    Image(systemName: "square.and.arrow.up").opacity(busy ? 0 : 1)
                    ProgressView().tint(.white).opacity(busy ? 1 : 0)
                }
                .accessibilityHidden(true)
                Text("Export \(title)")
            }
            .font(.tBodySemibold)
            .frame(maxWidth: .infinity, minHeight: 48)
            .foregroundStyle(.white)
            .background(RoundedRectangle(cornerRadius: 16).fill(Theme.raised))
        }
        .buttonStyle(PressableStyle())
        .disabled(busy)
    }
}
