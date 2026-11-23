import SwiftUI

/// "Expenses" title with search (left) and filters (right).
struct HistoryHeader: View {
    @Binding var searching: Bool
    let filtersActive: Bool
    let showFilters: () -> Void
    let endSearch: () -> Void

    var body: some View {
        ZStack {
            Text("Expenses").font(.tTitle).accessibilityAddTraits(.isHeader)
            HStack {
                Button(searching ? "Close search" : "Search", systemImage: searching ? "xmark" : "magnifyingglass", action: toggleSearch)
                    .labelStyle(.iconOnly)
                    .font(.app(20, .medium))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 44, height: 44)
                Spacer()
                Button("Filters", systemImage: "slider.horizontal.3", action: showFilters)
                    .labelStyle(.iconOnly)
                    .font(.app(22, .medium))
                    .frame(width: 44, height: 44)
                    .overlay(alignment: .topTrailing) {
                        Circle().fill(Theme.danger).frame(width: 9, height: 9).offset(x: -4, y: 6)
                            .opacity(filtersActive ? 1 : 0)
                            .accessibilityHidden(true)
                    }
                    .accessibilityValue(filtersActive ? "Active" : "")
            }
            .foregroundStyle(.white)
        }
        .padding(.horizontal, Theme.gutter - 8)
        .frame(height: 56)
    }

    private func toggleSearch() {
        withAnimation(.snappy) { searching.toggle() }
        if !searching { endSearch() }
    }
}
