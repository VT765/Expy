import SwiftUI

/// 3×4 keypad with large rounded dark keys. Holding backspace clears.
/// `leftAccessory` replaces the "." key when `showsDecimal` is false.
struct NumPad<Accessory: View>: View {
    var showsDecimal = true
    var keyHeight = 63.0
    @ViewBuilder var leftAccessory: Accessory
    var onKey: (String) -> Void
    var onBackspace: () -> Void
    var onClear: () -> Void

    private let digits = ["1", "2", "3", "4", "5", "6", "7", "8", "9"]

    var body: some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(0..<3, id: \.self) { row in
                GridRow {
                    ForEach(digits[(row * 3)..<(row * 3 + 3)], id: \.self) { d in
                        NumPadKey(label: d, height: keyHeight) { onKey(d) }
                    }
                }
            }
            GridRow {
                if showsDecimal {
                    NumPadKey(label: ".", accessibilityName: "Decimal point", height: keyHeight) { onKey(".") }
                } else {
                    leftAccessory.frame(maxWidth: .infinity, minHeight: keyHeight)
                }
                NumPadKey(label: "0", height: keyHeight) { onKey("0") }
                NumPadKey(systemImage: "arrow.left", accessibilityName: "Delete", height: keyHeight, action: onBackspace)
                    .simultaneousGesture(LongPressGesture(minimumDuration: 0.45).onEnded { _ in clearAll() })
                    .accessibilityHint("Hold to clear")
            }
        }
    }

    private func clearAll() {
        Haptics.soft()
        onClear()
    }
}

extension NumPad where Accessory == EmptyView {
    init(showsDecimal: Bool = true, keyHeight: Double = 63, onKey: @escaping (String) -> Void,
         onBackspace: @escaping () -> Void, onClear: @escaping () -> Void) {
        self.init(showsDecimal: showsDecimal, keyHeight: keyHeight, leftAccessory: { EmptyView() },
                  onKey: onKey, onBackspace: onBackspace, onClear: onClear)
    }
}
