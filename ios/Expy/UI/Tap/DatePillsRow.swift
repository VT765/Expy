import SwiftUI

/// Today / Yesterday / Pick date.
struct DatePillsRow: View {
    @Bindable var model: TapModel
    @State private var picking = false

    var body: some View {
        HStack(spacing: 10) {
            DatePill(title: "Today", on: model.dateMode == .today) { model.dateMode = .today }
            DatePill(title: "Yesterday", on: model.dateMode == .yesterday) { model.dateMode = .yesterday }
            DatePill(title: model.dateMode == .pick ? model.pickedDay.formatted(.dateTime.month(.abbreviated).day()) : "Pick date",
                     on: model.dateMode == .pick, action: pick)
        }
        .sheet(isPresented: $picking) {
            DatePickSheet(date: $model.pickedDay, done: usePickedDate)
        }
    }

    private func pick() { picking = true }

    private func usePickedDate() {
        model.dateMode = .pick
        picking = false
    }
}
