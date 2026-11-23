import SwiftUI

/// Thin progress capsule filled to `fraction` (0…1), laid out without
/// GeometryReader.
struct FractionBar: View {
    let fraction: Double
    let color: Color
    var height = 6.0

    var body: some View {
        FractionLayout(fraction: min(1, max(0, fraction))) {
            Capsule().fill(Theme.raised)
            Capsule().fill(color)
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityValue(Text(fraction, format: .percent.precision(.fractionLength(0))))
    }
}
