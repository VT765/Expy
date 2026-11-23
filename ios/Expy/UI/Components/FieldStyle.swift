import SwiftUI

/// Input field style used in sheets.
struct FieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.tBody)
            .padding(.horizontal, 16)
            .frame(minHeight: 48)
            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.raised))
    }
}

extension View {
    func fieldStyle() -> some View { modifier(FieldStyle()) }
}
