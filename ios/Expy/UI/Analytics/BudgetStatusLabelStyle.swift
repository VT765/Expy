import SwiftUI

/// Shows the warning icon only when over budget (so the cue isn't colour-only).
struct BudgetStatusLabelStyle: LabelStyle {
    let showsIcon: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            if showsIcon { configuration.icon }
            configuration.title
        }
    }
}
