import SwiftUI

/// ‹ November 2026 › navigation, or From/To pickers for a custom range.
struct PeriodSelector: View {
    let kind: PeriodKind
    let label: String
    @Binding var offset: Int
    @Binding var from: Date
    @Binding var to: Date
    let onChange: () -> Void

    var body: some View {
        if kind == .custom {
            HStack {
                DatePicker("From", selection: $from, in: ...to, displayedComponents: .date).labelsHidden()
                Text("–").foregroundStyle(Theme.sub).accessibilityHidden(true)
                DatePicker("To", selection: $to, in: from..., displayedComponents: .date).labelsHidden()
            }
            .frame(maxWidth: .infinity)
        } else {
            HStack {
                PeriodNavButton(title: "Previous period", icon: "chevron.left", action: previous)
                Spacer()
                Text(label).font(.app(16, .semibold))
                Spacer()
                PeriodNavButton(title: "Next period", icon: "chevron.right", action: next)
                    .disabled(offset >= 0)
            }
        }
    }

    private func previous() {
        onChange()
        offset -= 1
    }

    private func next() {
        onChange()
        offset += 1
    }
}
