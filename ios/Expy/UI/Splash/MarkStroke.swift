import SwiftUI

/// One white rectangle of the "E", given in icon units (1024 pt icon) and
/// placed inside the mark's 360 × 492 unit frame. It grows from its own
/// edge (`anchor`), not the mark's.
struct MarkStroke: View {
    let x: Double
    let y: Double
    let w: Double
    let h: Double
    /// Points per icon unit.
    let unit: Double
    var scaleX = 1.0
    var scaleY = 1.0
    var anchor = UnitPoint.center

    var body: some View {
        Rectangle().fill(.white)
            .frame(width: w * unit, height: h * unit)
            .scaleEffect(x: scaleX, y: scaleY, anchor: anchor)
            .padding(.leading, x * unit).padding(.top, y * unit)
            .frame(width: 360 * unit, height: 492 * unit, alignment: .topLeading)
    }
}
