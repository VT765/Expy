/// Fire-and-forget haptics, played by the root view's `sensoryFeedback`.
enum Haptics {
    @MainActor static func tap() { HapticFeedback.shared.play(.impact(weight: .light)) }
    @MainActor static func soft() { HapticFeedback.shared.play(.impact(flexibility: .soft)) }
    @MainActor static func success() { HapticFeedback.shared.play(.success) }
    @MainActor static func error() { HapticFeedback.shared.play(.error) }
    @MainActor static func selection() { HapticFeedback.shared.play(.selection) }
}
