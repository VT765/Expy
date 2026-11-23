import SwiftUI

/// "▲ ₹1,200" (red, spent more), "▼ ₹300" (green), or "New" when the
/// category had no spending last period.
struct CategoryChange: View {
    let now: Double
    let before: Double?

    var body: some View {
        if let before, before > 0 {
            let delta = now - before
            if abs(delta) >= 1 {
                Label(Fmt.money(abs(delta)), systemImage: delta > 0 ? "arrow.up.right" : "arrow.down.right")
                    .foregroundStyle(delta > 0 ? Theme.danger : Theme.positive)
                    .accessibilityLabel("\(delta > 0 ? "Up" : "Down") \(Fmt.money(abs(delta))) versus previous period")
            } else {
                Text("No change").foregroundStyle(Theme.sub)
            }
        } else {
            Text("New").foregroundStyle(Theme.sub)
                .accessibilityLabel("No spending in the previous period")
        }
    }
}
