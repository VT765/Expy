import SwiftUI

/// "To" followed by every other account as a chip; replaces the category
/// chips while logging a transfer.
struct TransferTargetRow: View {
    let accounts: [Account]
    let fromId: String?
    let selectedId: String?
    let select: (String) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                Text("To").font(.app(13, .semibold)).foregroundStyle(Theme.sub)
                ForEach(accounts.filter { $0.id != fromId }) { a in
                    AccountChip(account: a, selected: a.id == selectedId) { pick(a.id) }
                }
            }
            .padding(.horizontal, Theme.gutter)
        }
        .scrollIndicators(.hidden)
        .frame(height: 44)
        .excludedFromPageSwipe()
    }

    private func pick(_ id: String) {
        Haptics.selection()
        select(id)
    }
}
