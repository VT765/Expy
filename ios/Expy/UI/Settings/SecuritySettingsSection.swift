import SwiftUI

/// App Lock, PIN, Face ID and auto-lock.
struct SecuritySettingsSection: View {
    @State private var lock = LockManager.shared
    @State private var pinFlow: PinFlow?
    @State private var lockOn = false
    @State private var faceIdOn = false

    enum PinFlow: String, Identifiable {
        case create, change, disable
        var id: String { rawValue }
    }

    var body: some View {
        SettingsSection(title: "Security") {
            SettingsRow(title: "App Lock", subtitle: "Require a PIN to open Expy", chevron: false, action: nil) {
                Toggle("App Lock", isOn: $lockOn).labelsHidden().tint(Theme.positive)
            }
            if lock.enabled {
                SettingsRow(title: "Change PIN", action: changePin)
                if lock.biometryAvailable {
                    SettingsRow(title: lock.biometryName, subtitle: "Unlock with \(lock.biometryName), PIN as fallback", chevron: false, action: nil) {
                        Toggle(lock.biometryName, isOn: $faceIdOn).labelsHidden().tint(Theme.positive)
                    }
                }
                Menu {
                    Picker("Auto-lock", selection: $lock.autoLock) {
                        ForEach(LockManager.AutoLock.allCases) { Text($0.label).tag($0) }
                    }
                } label: {
                    SettingsRow(title: "Auto-lock", value: lock.autoLock.label, chevron: false, action: nil) { EmptyView() }
                }
            }
        }
        .onAppear(perform: syncToggles)
        .onChange(of: lockOn) { _, on in lockToggled(on) }
        .onChange(of: faceIdOn) { _, on in faceIdToggled(on) }
        .sheet(item: $pinFlow, onDismiss: syncToggles) { flow in
            switch flow {
            case .create: PinSetupView(mode: .create)
            case .change: PinSetupView(mode: .change)
            case .disable: PinSetupView(mode: .verify, onVerified: LockManager.shared.disable)
            }
        }
    }

    private func syncToggles() {
        lockOn = lock.enabled
        faceIdOn = lock.faceIdEnabled
    }

    private func changePin() { pinFlow = .change }

    /// Turning the switch starts the PIN flow; the switch settles once it ends.
    private func lockToggled(_ on: Bool) {
        guard on != lock.enabled else { return }
        pinFlow = on ? .create : .disable
    }

    private func faceIdToggled(_ on: Bool) {
        guard on != lock.faceIdEnabled else { return }
        Task {
            _ = await lock.setFaceId(on)
            faceIdOn = lock.faceIdEnabled
        }
    }
}
