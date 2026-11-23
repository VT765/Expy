import SwiftUI

/// Sign in (or first-time setup) with a numeric password.
struct LoginView: View {
    enum Status { case loading, setup, login, unreachable }
    @State private var status = Status.loading
    @State private var password = ""
    @State private var confirm = ""
    @State private var error = ""
    @State private var busy = false
    @State private var showServer = false

    private struct StatusReply: Decodable { let configured: Bool }
    private struct Payload: Encodable { let password: String }
    private struct TokenReply: Decodable { let token: String }

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text(status == .setup ? "Set up Expy" : "Welcome back").font(.system(size: 26, weight: .bold))
            Text(status == .setup ? "Create a password to sync your expenses."
                 : status == .unreachable ? "Can't reach the server right now." : "Sign in to sync your expenses.")
                .font(.tBody).foregroundStyle(Theme.sub).padding(.top, 6)

            VStack(spacing: 12) {
                switch status {
                case .loading:
                    ProgressView().tint(.white).frame(height: 56)
                case .setup, .login:
                    NumericSecureField(placeholder: status == .setup ? "Password (8+ digits)" : "Password", text: $password)
                    if status == .setup { NumericSecureField(placeholder: "Confirm password", text: $confirm) }
                    Text(error).font(.tFootnote).foregroundStyle(Theme.danger).frame(maxWidth: .infinity, alignment: .leading).frame(minHeight: 18)
                    PrimaryButton(title: status == .setup ? "Create account" : "Sign in", isLoading: busy, action: submit)
                        .disabled(password.isEmpty || (status == .setup && (password.count < 8 || confirm.isEmpty)))
                case .unreachable:
                    PrimaryButton(title: "Try again", role: .secondary) { Task { await check() } }
                }
            }
            .padding(.top, 36)
            Spacer()
            Button("Server: \(URL(string: APIClient.shared.serverURL)?.host ?? "—")") { showServer = true }
                .font(.tFootnote).foregroundStyle(Theme.faint)
            Button("Use without sync on this device") { Session.shared.offlineMode = true }
                .font(.tFootnote).foregroundStyle(Theme.sub).padding(.vertical, 14)
        }
        .padding(.horizontal, Theme.gutter)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.canvas)
        .task { await check() }
        .sheet(isPresented: $showServer, onDismiss: { Task { await check() } }) { ServerSheet() }
    }

    private func check() async {
        status = .loading
        do {
            let r: StatusReply = try await APIClient.shared.request("auth/status", auth: false)
            status = r.configured ? .login : .setup
        } catch { status = .unreachable }
    }

    private func submit() {
        error = ""
        if status == .setup && password != confirm { error = "Passwords don't match"; return }
        busy = true
        Task {
            defer { busy = false }
            do {
                let r: TokenReply = try await APIClient.shared.request(status == .setup ? "auth/setup" : "auth/login", method: "POST",
                                                                       body: Payload(password: password), auth: false)
                Session.shared.signedIn(token: r.token)
                Haptics.success()
                ToastCenter.shared.show(status == .setup ? "Account created" : "Signed in")
            } catch { self.error = error.localizedDescription }
        }
    }
}
