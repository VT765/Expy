import SwiftUI

/// Graphical date picker for "Pick date".
struct DatePickSheet: View {
    @Binding var date: Date
    var done: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            DatePicker("Date", selection: $date, in: ...Date.now, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(.white)
            PrimaryButton(title: "Use this date", action: done)
        }
        .padding(Theme.gutter)
        .presentationDetents([.medium, .large])
        .presentationBackground(Theme.card)
    }
}
