import SwiftUI

/// Full-width primary button: white with black text, grey well when disabled.
struct PrimaryButton: View {
    let title: String
    var role: Role = .primary
    var isLoading = false
    var icon: String?
    var action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    enum Role { case primary, secondary, destructive }

    var body: some View {
        Button(action: action) {
            ZStack {
                Label {
                    Text(title)
                } icon: {
                    if let icon { Image(systemName: icon).symbolEffect(.bounce, value: icon) }
                }
                .labelStyle(.titleAndIcon)
                .opacity(isLoading ? 0 : 1)
                ProgressView().tint(role == .primary ? .black : .white).opacity(isLoading ? 1 : 0)
            }
            .font(.app(16, .bold))
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(foreground)
            .background(RoundedRectangle(cornerRadius: 20).fill(background))
        }
        .buttonStyle(PressableStyle(scale: 0.97))
        .disabled(isLoading)
    }

    private var background: Color {
        if !isEnabled { return Theme.well }
        return role == .primary ? .white : Theme.raised
    }

    private var foreground: Color {
        if !isEnabled { return Theme.faint }
        return switch role {
        case .primary: .black
        case .secondary: .white
        case .destructive: Theme.danger
        }
    }
}
