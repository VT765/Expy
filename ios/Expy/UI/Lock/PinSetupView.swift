import SwiftUI

/// [verify current] → new → confirm.
struct PinSetupView: View {
    enum Mode { case create, change, verify }
    enum Step { case current, new, confirm }

    let mode: Mode
    var onVerified: (() -> Void)?
    @State private var step: Step = .new
    @State private var first = ""
    @State private var error = " "
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack {
            HStack {
                Button("Cancel", systemImage: "xmark", action: cancel)
                    .labelStyle(.iconOnly)
                    .font(.app(20, .semibold))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 8)
            Spacer()
            PinPad(title: title, subtitle: error, onComplete: handle).id(step)
            Spacer()
        }
        .background(Theme.canvas)
        .onAppear(perform: start)
        .interactiveDismissDisabled()
    }

    private var title: String {
        switch step {
        case .current: mode == .verify ? "Enter your PIN" : "Enter current PIN"
        case .new: "Create a 4-digit PIN"
        case .confirm: "Enter it again"
        }
    }

    private func start() { step = mode == .create ? .new : .current }
    private func cancel() { dismiss() }

    private func handle(_ pin: String) -> Bool {
        let lock = LockManager.shared
        switch step {
        case .current:
            guard lock.checkPin(pin) else { error = "Wrong PIN"; return false }
            if mode == .verify {
                onVerified?()
                dismiss()
                return true
            }
            error = " "
            step = .new
            return true
        case .new:
            first = pin
            error = " "
            step = .confirm
            return true
        case .confirm:
            guard pin == first else {
                error = "PINs didn't match. Try again."
                step = .new
                return false
            }
            lock.setPin(pin)
            Haptics.success()
            ToastCenter.shared.show(mode == .change ? "PIN changed" : "App Lock is on")
            dismiss()
            return true
        }
    }
}
