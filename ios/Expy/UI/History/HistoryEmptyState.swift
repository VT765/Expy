import SwiftUI

/// Native empty states for "no entries" and "no matches".
struct HistoryEmptyState: View {
    let filtering: Bool
    let clear: () -> Void

    var body: some View {
        VStack {
            if filtering {
                ContentUnavailableView {
                    Label("No matches", systemImage: "magnifyingglass")
                } description: {
                    Text("Nothing fits this view in this range.")
                } actions: {
                    Button("Clear filters", action: clear).buttonStyle(.bordered).tint(.white)
                }
            } else {
                ContentUnavailableView("Nothing here yet", systemImage: "list.bullet.rectangle",
                                       description: Text("Log your first expense from the Tap tab."))
            }
        }
        .frame(maxHeight: .infinity)
    }
}
