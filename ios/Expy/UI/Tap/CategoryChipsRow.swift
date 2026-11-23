import SwiftUI

/// Horizontally scrolling category chips; keeps the selection in view.
struct CategoryChipsRow: View {
    let categories: [ExpenseCategory]
    let selectedId: String?
    let select: (String) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(categories) { c in
                        CategoryChip(category: c, selected: c.id == selectedId) { select(c.id) }.id(c.id)
                    }
                }
                .padding(.horizontal, Theme.gutter)
            }
            .scrollIndicators(.hidden)
            .frame(height: 44)
            .excludedFromPageSwipe()
            .onAppear { proxy.scrollTo(selectedId, anchor: .center) }
            .onChange(of: selectedId) { _, id in withAnimation { proxy.scrollTo(id, anchor: .center) } }
        }
    }
}
