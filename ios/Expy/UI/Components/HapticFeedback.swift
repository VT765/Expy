import Observation
import SwiftUI

/// Queues one haptic at a time; `RootView` plays it via `sensoryFeedback`.
@MainActor
@Observable
final class HapticFeedback {
    static let shared = HapticFeedback()

    private(set) var tick = 0
    @ObservationIgnored private(set) var pending: SensoryFeedback = .selection

    func play(_ feedback: SensoryFeedback) {
        pending = feedback
        tick &+= 1
    }
}
