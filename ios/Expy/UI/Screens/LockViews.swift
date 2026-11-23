import SwiftUI

/// 4 dots + keypad (same key style as Tap). Calls onComplete with the PIN;
/// return false to shake and clear.
struct PinPad: View {
    let title: String
    var subtitle: String = " "
    var disabled = false
    var faceId: (() -> Void)? = nil
    var onComplete: (String) -> Bool
    @State private var pin = ""
    @State private var shake: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            Text(title).font(.system(size: 20, weight: .bold))
            Text(subtitle).font(.tFootnote).foregroundStyle(Theme.sub).frame(height: 20).padding(.top, 6)
            HStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { i in
                    Circle()
                        .strokeBorder(.white, lineWidth: 1.5)
                        .background(Circle().fill(i < pin.count ? .white : .clear))
                        .frame(width: 14, height: 14)
                        .scaleEffect(i < pin.count ? 1.1 : 1)
                }
            }
            .modifier(Shake(amount: shake))
            .padding(.top, 28)
            NumPad(showsDecimal: false, keyHeight: 68,
                   leftAccessory: faceId.map { action in
                       AnyView(Button(action: action) { Image(systemName: "faceid").font(.system(size: 30)).frame(maxWidth: .infinity, minHeight: 68) }
                           .foregroundStyle(.white).accessibilityLabel("Use Face ID"))
                   },
                   onKey: press, onBackspace: { if !pin.isEmpty { pin.removeLast() } }, onClear: { pin = "" })
                .frame(maxWidth: 340)
                .padding(.horizontal, 16)
                .padding(.top, 48)
                .disabled(disabled)
                .opacity(disabled ? 0.3 : 1)
        }
    }

    private func press(_ k: String) {
        guard pin.count < 4 else { return }
        pin += k
        guard pin.count == 4 else { return }
        let entered = pin
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            if onComplete(entered) {
                pin = ""
            } else {
                Haptics.error()
                withAnimation(.linear(duration: 0.45)) { shake += 1 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { pin = "" }
            }
        }
    }
}

struct Shake: GeometryEffect {
    var amount: CGFloat
    var animatableData: CGFloat {
        get { amount }
        set { amount = newValue }
    }
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 14 * sin(amount * .pi * 6), y: 0))
    }
}

/// Black lock screen. Face ID auto-prompts with "Use PIN" fallback; 30s
/// cooldown after 5 wrong PINs.
struct LockView: View {
    @State private var lock = LockManager.shared
    @State private var usePin = !LockManager.shared.faceIdEnabled
    @State private var now = Date()
    @State private var message = " "
    @State private var forgot = false
    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    private var cooling: Bool { (lock.cooldownUntil ?? .distantPast) > now }

    var body: some View {
        VStack {
            Spacer()
            if usePin {
                PinPad(title: "Enter PIN",
                       subtitle: cooling ? "Too many attempts. Try again in \(Int(ceil(lock.cooldownUntil!.timeIntervalSince(now))))s" : message,
                       disabled: cooling,
                       faceId: lock.faceIdEnabled ? { Task { await lock.unlockWithBiometrics() } } : nil) { pin in
                    switch lock.attempt(pin) {
                    case .ok: Haptics.success(); return true
                    case .wrong: message = "Wrong PIN · \(lock.attemptsLeft) \(lock.attemptsLeft == 1 ? "try" : "tries") left"; return false
                    case .cooldown: now = Date(); return false
                    }
                }
            } else {
                VStack(spacing: 14) {
                    Image(systemName: "lock.fill").font(.system(size: 30)).foregroundStyle(Theme.sub)
                    Text("Expy is locked").font(.system(size: 20, weight: .bold))
                    Button { Task { await lock.unlockWithBiometrics() } } label: {
                        VStack(spacing: 12) {
                            Image(systemName: "faceid").font(.system(size: 60, weight: .light))
                            Text("Tap to unlock with \(lock.biometryName)").font(.tBody).foregroundStyle(Theme.sub)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.top, 30)
                    Button("Use PIN") { usePin = true }
                        .font(.tBodySemibold).foregroundStyle(.white)
                        .frame(width: 160, height: 48)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.raised))
                        .padding(.top, 40)
                }
            }
            Spacer()
            Button("Forgot PIN?") { forgot = true }.font(.tFootnote).foregroundStyle(Theme.sub).padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.canvas)
        .onReceive(timer) { now = $0 }
        .task { if lock.faceIdEnabled { await lock.unlockWithBiometrics() } }
        .alert("Forgot PIN?", isPresented: $forgot) {
            Button(Session.shared.isSignedIn ? "Sign out" : "Erase & reset", role: .destructive) {
                Task {
                    if Session.shared.isSignedIn { _ = await SyncEngine.shared.flush() }
                    Session.shared.wipeDevice()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(Session.shared.isSignedIn
                 ? "You'll be signed out. Sign in with your password to get back in. Your data is safe on the server."
                 : "This device isn't signed in, so the only way back in is to erase the data on this device.")
        }
    }
}

/// [verify current] → new → confirm.
struct PinSetupView: View {
    enum Mode { case create, change, verify }
    let mode: Mode
    var onVerified: (() -> Void)? = nil
    @State private var step: Step = .new
    @State private var first = ""
    @State private var error = " "
    @Environment(\.dismiss) private var dismiss

    enum Step { case current, new, confirm }

    var body: some View {
        VStack {
            HStack {
                Button { dismiss() } label: { Image(systemName: "xmark").font(.system(size: 20, weight: .semibold)).frame(width: 44, height: 44) }
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 8)
            Spacer()
            PinPad(title: title, subtitle: error, onComplete: handle).id(step)
            Spacer()
        }
        .background(Theme.canvas)
        .onAppear { step = mode == .create ? .new : .current }
        .interactiveDismissDisabled()
    }

    private var title: String {
        switch step {
        case .current: mode == .verify ? "Enter your PIN" : "Enter current PIN"
        case .new: "Create a 4-digit PIN"
        case .confirm: "Enter it again"
        }
    }

    private func handle(_ pin: String) -> Bool {
        let lock = LockManager.shared
        switch step {
        case .current:
            guard lock.checkPin(pin) else { error = "Wrong PIN"; return false }
            if mode == .verify { onVerified?(); dismiss(); return true }
            error = " "; step = .new; return true
        case .new:
            first = pin; error = " "; step = .confirm; return true
        case .confirm:
            guard pin == first else { error = "PINs didn't match. Try again."; step = .new; return false }
            lock.setPin(pin)
            Haptics.success()
            ToastCenter.shared.show(mode == .change ? "PIN changed" : "App Lock is on")
            dismiss()
            return true
        }
    }
}
