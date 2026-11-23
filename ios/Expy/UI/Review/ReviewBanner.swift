import SwiftUI

/// "3 bank messages to review ›" above History.
struct ReviewBanner: View {
    let count: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "message.badge.filled.fill").font(.app(18, .semibold)).foregroundStyle(Theme.positive)
                    .accessibilityHidden(true)
                Text("\(count) bank \(count == 1 ? "message" : "messages") to review").font(.app(15, .semibold))
                Spacer()
                Image(systemName: "chevron.right").font(.app(13, .semibold)).foregroundStyle(Theme.sub).accessibilityHidden(true)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16).frame(minHeight: 52)
            .background(RoundedRectangle(cornerRadius: Theme.cardRadius).fill(Theme.card))
            .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).strokeBorder(Theme.positive.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
        .accessibilityHint("Opens suggested entries from your bank messages")
    }
}
