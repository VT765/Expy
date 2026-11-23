import SwiftUI

/// Lays out a full-width track (first subview) and a fill (second subview)
/// sized to `fraction` of the proposed width.
struct FractionLayout: Layout {
    let fraction: Double

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        CGSize(width: proposal.width ?? 100, height: proposal.height ?? 6)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        subviews[0].place(at: bounds.origin, proposal: ProposedViewSize(bounds.size))
        let fill = CGSize(width: bounds.width * fraction, height: bounds.height)
        subviews[1].place(at: bounds.origin, proposal: ProposedViewSize(fill))
    }
}
