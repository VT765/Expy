import SwiftUI

/// Horizontally scrolling current balance per account.
struct AccountBalancesStrip: View {
    let accounts: [Account]
    let balances: [String: Double]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(accounts) { a in
                    AccountBalanceCard(account: a, balance: balances[a.id] ?? 0)
                }
            }
        }
        .scrollIndicators(.hidden)
        .excludedFromPageSwipe()
    }
}
