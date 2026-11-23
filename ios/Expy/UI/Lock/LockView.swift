import SwiftUI

/// Black lock screen. Face ID auto-prompts with "Use PIN" fallback; 30s
/// cooldown after 5 wrong PINs.
struct LockView: View {
    @State private var lock = LockManager.shared
    @State private var usePin = !LockManager.shared.faceIdEnabled
    @State private var now = Date.now
    @State private var message = " "
    @State private var forgot = false

    private var cooling: Bool { (lock.cooldownUntil ?? .distantPast) > now }

    private var subtitle: String {
        guard cooling, let until = lock.cooldownUntil else { return message }
        return "Too many attempts. Try again in \(Int(ceil(until.timeIntervalSince(now))))s"
    }

    var body: some View {
        VStack {
            Spacer()
            if usePin {
                PinPad(title: "Enter PIN", subtitle: subtitle, disabled: cooling,
                       faceId: lock.faceIdEnabled ? unlockWithFaceId : nil, onComplete: attempt)
            } else {
                FaceIdPrompt(biometryName: lock.biometryName, unlock: unlockWithFaceId, usePin: showPin)
            }
            Spacer()
            Button("Forgot PIN?", action: askForgot)
                .font(.tFootnote).foregroundStyle(Theme.sub)
                .frame(minHeight: 44)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.canvas)
        .task(id: cooling) { await tickCooldown() }
        .task { await autoPrompt() }
        .alert("Forgot PIN?", isPresented: $forgot) {
            Button("Erase & reset", role: .destructive, action: eraseAndReset)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your data is protected by the PIN, so the only way back in is to erase Expy's data on this device. Restore a JSON backup afterwards if you have one.")
        }
    }

    private func attempt(_ pin: String) -> Bool {
        switch lock.attempt(pin) {
        case .ok:
            Haptics.success()
            return true
        case .wrong:
            message = "Wrong PIN · \(lock.attemptsLeft) \(lock.attemptsLeft == 1 ? "try" : "tries") left"
            return false
        case .cooldown:
            now = .now
            return false
        }
    }

    /// Refreshes the countdown twice a second while a cooldown runs.
    private func tickCooldown() async {
        while cooling, !Task.isCancelled {
            try? await Task.sleep(for: .milliseconds(500))
            now = .now
        }
    }

    private func autoPrompt() async {
        if lock.faceIdEnabled { await lock.unlockWithBiometrics() }
    }

    private func unlockWithFaceId() { Task { await lock.unlockWithBiometrics() } }
    private func showPin() { usePin = true }
    private func askForgot() { forgot = true }

    private func eraseAndReset() {
        DataStore.shared.resetLocal()
        LockManager.shared.disable()
    }
}
