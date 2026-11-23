import SwiftUI

/// Lock screen state shown before falling back to the PIN pad.
struct FaceIdPrompt: View {
    let biometryName: String
    let unlock: () -> Void
    let usePin: () -> Void

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "lock.fill").font(.app(30)).foregroundStyle(Theme.sub).accessibilityHidden(true)
            Text("Expy is locked").font(.app(20, .bold))
            Button(action: unlock) {
                VStack(spacing: 12) {
                    Image(systemName: "faceid").font(.app(60, .light)).accessibilityHidden(true)
                    Text("Tap to unlock with \(biometryName)").font(.tBody).foregroundStyle(Theme.sub)
                }
            }
            .foregroundStyle(.white)
            .padding(.top, 30)
            Button("Use PIN", action: usePin)
                .font(.tBodySemibold).foregroundStyle(.white)
                .frame(width: 160, height: 48)
                .background(RoundedRectangle(cornerRadius: 16).fill(Theme.raised))
                .padding(.top, 40)
        }
    }
}
