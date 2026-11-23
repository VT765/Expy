import SwiftUI

/// Account picker on the left ("From" for transfers); Credit and Transfer
/// pills on the right. Neither pill selected = debit.
struct AccountKindRow: View {
    let accounts: [Account]
    @Binding var accountId: String
    let selected: Account?
    let model: TapModel

    var body: some View {
        HStack(spacing: 8) {
            if !accounts.isEmpty {
                Menu {
                    Picker(model.isTransfer ? "From account" : "Account", selection: $accountId) {
                        ForEach(accounts) { a in Label(a.name, systemImage: a.symbol).tag(a.id) }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: selected?.symbol ?? "banknote").font(.app(11, .semibold))
                        Text(model.isTransfer ? "From \(selected?.name ?? "account")" : selected?.name ?? "Account")
                            .font(.app(13, .semibold)).lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down").font(.app(10, .bold))
                    }
                    .padding(.horizontal, 14).frame(minHeight: 44)
                    .foregroundStyle(.white)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Theme.raised))
                }
                .accessibilityLabel("\(model.isTransfer ? "From account" : "Account"): \(selected?.name ?? "none")")
            }
            Spacer(minLength: 0)
            KindPill(title: "Credit", on: model.kind == .credit) { model.toggle(.credit) }
            if accounts.count > 1 {
                KindPill(title: "Transfer", on: model.isTransfer) { model.toggle(.transfer) }
            }
        }
        .padding(.horizontal, 16)
    }
}
