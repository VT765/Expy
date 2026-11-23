import SwiftUI

/// 4 dots + keypad (same key style as Tap). Calls `onComplete` with the PIN;
/// returning false shakes the dots and clears.
struct PinPad: View {
    let title: String
    var subtitle = " "
    var disabled = false
    var faceId: (() -> Void)?
    var onComplete: (String) -> Bool
    @State private var pin = ""
    @State private var shake = 0.0
    @State private var flash = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Text(title).font(.app(20, .bold))
            Text(subtitle).font(.tFootnote).foregroundStyle(Theme.sub).frame(minHeight: 20).padding(.top, 6)
            HStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .strokeBorder(.white, lineWidth: 1.5)
                        .background(Circle().fill(i < pin.count ? .white : .clear))
                        .frame(width: 14, height: 14)
                        .scaleEffect(i < pin.count ? 1.1 : 1)
                }
            }
            .modifier(ShakeEffect(amount: shake))
            .opacity(flash ? 0.3 : 1)
            .padding(.top, 28)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(pin.count) of 4 digits entered")
            NumPad(showsDecimal: false, keyHeight: 68) {
                if let faceId {
                    Button("Use Face ID", systemImage: "faceid", action: faceId)
                        .labelStyle(.iconOnly)
                        .font(.app(30))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, minHeight: 68)
                }
            } onKey: { press($0) } onBackspace: {
                deleteDigit()
            } onClear: {
                pin = ""
            }
            .frame(maxWidth: 340)
            .padding(.horizontal, 16)
            .padding(.top, 48)
            .disabled(disabled)
            .opacity(disabled ? 0.3 : 1)
        }
    }

    private func deleteDigit() {
        if !pin.isEmpty { pin.removeLast() }
    }

    private func press(_ k: String) {
        guard pin.count < 4 else { return }
        pin += k
        guard pin.count == 4 else { return }
        let entered = pin
        Task {
            try? await Task.sleep(for: .milliseconds(80))
            if onComplete(entered) {
                pin = ""
            } else {
                await rejectAnimation()
                pin = ""
            }
        }
    }

    /// Shake, or with Reduce Motion a brief fade, then wait for it to finish.
    private func rejectAnimation() async {
        Haptics.error()
        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.2)) { flash = true }
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.easeInOut(duration: 0.2)) { flash = false }
        } else {
            withAnimation(.linear(duration: 0.45)) { shake += 1 }
            try? await Task.sleep(for: .milliseconds(450))
        }
    }
}
