import SwiftUI

/// Small chip that fills the note with a recently used one.
struct RecentNoteChip: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(text).font(.app(12, .medium)).lineLimit(1)
                .padding(.horizontal, 10).frame(height: 24)
                .foregroundStyle(Theme.sub)
                .background(Capsule().fill(Theme.raised))
                .frame(minHeight: 44)
                .contentShape(.rect)
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel("Use note \(text)")
    }
}
