import SwiftUI

/// Inline search for notes and category names.
struct HistorySearchField: View {
    @Binding var query: String
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(Theme.faint).accessibilityHidden(true)
            TextField("Search notes and categories", text: $query)
                .focused($focused)
                .submitLabel(.search)
                .autocorrectionDisabled()
            Button("Clear search", systemImage: "xmark.circle.fill", action: clear)
                .labelStyle(.iconOnly)
                .foregroundStyle(Theme.faint)
                .frame(minWidth: 44, minHeight: 44)
                .opacity(query.isEmpty ? 0 : 1)
        }
        .font(.app(15))
        .padding(.leading, 14).frame(minHeight: 44)
        .background(RoundedRectangle(cornerRadius: 12).fill(Theme.raised))
        .padding(.horizontal, Theme.gutter).padding(.bottom, 10)
        .onAppear { focused = true }
    }

    private func clear() { query = "" }
}
