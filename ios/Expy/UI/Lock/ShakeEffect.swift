import SwiftUI

/// Horizontal shake; animate `amount` by +1 for one shake.
struct ShakeEffect: GeometryEffect {
    var amount: Double

    var animatableData: Double {
        get { amount }
        set { amount = newValue }
    }

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 14 * sin(amount * .pi * 6), y: 0))
    }
}
