import SwiftUI

/// Account name and balance; negative balances in red.
struct AccountBalanceCard: View {
    let account: Account
    let balance: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(account.name, systemImage: account.symbol).font(.app(13, .medium)).foregroundStyle(Theme.sub).lineLimit(1)
            Text(Fmt.money(balance)).font(.app(18, .bold)).monospacedDigit()
                .foregroundStyle(balance < 0 ? Theme.danger : .white)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .frame(minWidth: 130, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card))
        .accessibilityElement(children: .combine)
    }
}
