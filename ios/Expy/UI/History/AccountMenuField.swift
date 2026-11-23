import SwiftUI

/// Labelled account picker shown as a menu in a rounded field.
struct AccountMenuField: View {
    let title: String
    @Binding var selection: String?
    let accounts: [Account]
    var allowsNone = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.tFootnote).foregroundStyle(Theme.sub)
            Picker(title, selection: $selection) {
                if allowsNone || selection == nil { Text("None").tag(String?.none) }
                ForEach(accounts) { a in Label(a.name, systemImage: a.symbol).tag(Optional(a.id)) }
            }
            .pickerStyle(.menu)
            .tint(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 8).frame(minHeight: 48)
            .background(RoundedRectangle(cornerRadius: 14).fill(Theme.raised))
        }
    }
}
