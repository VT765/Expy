import SwiftUI

/// Launch animation over the app (≈1.2 s): the "E" builds stroke by stroke,
/// the underline draws like a progress bar, "Expy" fades in, then it all
/// eases forward and dissolves into the app. Reduce Motion: a short fade.
/// Tap to skip.
struct SplashView: View {
    let finish: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var started = false
    @State private var fadingOut = false

    static let duration = 1.25

    /// Debug screenshots: `-splashAt 0.4` holds the frame at 0.4 s.
    private var frozen: Double? {
        #if DEBUG
        Demo.value("-splashAt").flatMap(Double.init)
        #else
        nil
        #endif
    }

    @KeyframesBuilder<SplashValues>
    static func keyframes() -> some Keyframes<SplashValues> {
        KeyframeTrack(\.stem) {
            LinearKeyframe(0, duration: 0.05)
            SpringKeyframe(1, duration: 0.32, spring: .snappy)
        }
        KeyframeTrack(\.bar1) {
            LinearKeyframe(0, duration: 0.2)
            SpringKeyframe(1, duration: 0.3, spring: .snappy)
        }
        KeyframeTrack(\.bar2) {
            LinearKeyframe(0, duration: 0.27)
            SpringKeyframe(1, duration: 0.3, spring: .snappy)
        }
        KeyframeTrack(\.bar3) {
            LinearKeyframe(0, duration: 0.34)
            SpringKeyframe(1, duration: 0.3, spring: .snappy)
        }
        KeyframeTrack(\.line) {
            LinearKeyframe(0, duration: 0.42)
            CubicKeyframe(1, duration: 0.36)
        }
        KeyframeTrack(\.words) {
            LinearKeyframe(0, duration: 0.55)
            CubicKeyframe(1, duration: 0.3)
        }
        KeyframeTrack(\.exit) {
            LinearKeyframe(0, duration: 0.97)
            CubicKeyframe(1, duration: 0.28)
        }
    }

    var body: some View {
        ZStack {
            Theme.canvas.ignoresSafeArea()
            if let frozen {
                SplashLockup(values: KeyframeTimeline(initialValue: SplashValues(), content: SplashView.keyframes).value(time: frozen))
            } else if reduceMotion {
                SplashLockup(values: SplashValues(stem: 1, bar1: 1, bar2: 1, bar3: 1, line: 1, words: 1))
            } else {
                SplashLockup(values: SplashValues())
                    .keyframeAnimator(initialValue: SplashValues(), trigger: started) { _, v in
                        SplashLockup(values: v)
                    } keyframes: { _ in
                        SplashView.keyframes()
                    }
            }
        }
        .opacity(fadingOut ? 0 : 1)
        .contentShape(.rect)
        .onTapGesture(perform: skip)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Expy")
        .accessibilityAddTraits(.isImage)
        .task { await run() }
    }

    private func run() async {
        guard frozen == nil else { return }
        started = true
        try? await Task.sleep(for: .seconds(reduceMotion ? 0.6 : Self.duration))
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.25)) { fadingOut = true } completion: { finish() }
        } else {
            finish()
        }
    }

    private func skip() {
        withAnimation(.easeOut(duration: 0.2)) { fadingOut = true } completion: { finish() }
    }
}
