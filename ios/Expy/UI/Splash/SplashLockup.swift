import SwiftUI

/// Mark + wordmark for one frame of the splash timeline; `exit` zooms,
/// blurs and fades the whole lockup into the app.
struct SplashLockup: View {
    let values: SplashValues

    var body: some View {
        VStack(spacing: 28) {
            ExpyMark(width: 112, stem: values.stem, bars: [values.bar1, values.bar2, values.bar3], line: values.line)
            VStack(spacing: 6) {
                Text("Expy").font(.app(30, .bold)).tracking(0.5)
                Text("Every rupee, one tap away.").font(.app(14)).foregroundStyle(Theme.sub)
            }
            .opacity(values.words)
            .offset(y: (1 - values.words) * 8)
        }
        .compositingGroup() // fade as one image, so overlapping strokes don't show seams
        .scaleEffect(1 + values.exit * 0.12)
        .opacity(1 - values.exit)
        .blur(radius: values.exit * 6)
    }
}
