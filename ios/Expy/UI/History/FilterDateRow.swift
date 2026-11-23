import SwiftUI

/// "From" / "To" toggle with a date picker once enabled.
struct FilterDateRow: View {
    let title: String
    @Binding var isOn: Bool
    @Binding var date: Date

    var body: some View {
        HStack {
            Toggle(title, isOn: $isOn).tint(Theme.positive).font(.tBody)
            DatePicker(title, selection: $date, displayedComponents: .date)
                .labelsHidden()
                .opacity(isOn ? 1 : 0)
                .disabled(!isOn)
        }
        .padding(.horizontal, 16).frame(minHeight: 48)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.raised))
    }
}
