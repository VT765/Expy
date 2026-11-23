import SwiftUI

/// Single-choice list in a sheet.
struct OptionList<T: Hashable>: View {
    let title: String
    let options: [(T, String)]
    let selected: T
    var onSelect: (T) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(options.indices, id: \.self) { i in
                let (value, label) = options[i]
                Button {
                    choose(value)
                } label: {
                    HStack {
                        Text(label).foregroundStyle(.white)
                        Spacer()
                        if value == selected {
                            Image(systemName: "checkmark").foregroundStyle(.white).accessibilityLabel("Selected")
                        }
                    }
                }
                .listRowBackground(Theme.raised)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Theme.card)
    }

    private func choose(_ value: T) {
        onSelect(value)
        dismiss()
    }
}
