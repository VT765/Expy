import SwiftUI

/// Scale-down press feedback used across the app.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Full-width primary button: white with black text, grey well when disabled.
struct PrimaryButton: View {
    let title: String
    var role: Role = .primary
    var isLoading = false
    var action: () -> Void
    @Environment(\.isEnabled) private var isEnabled

    enum Role { case primary, secondary, destructive }

    var body: some View {
        Button(action: action) {
            ZStack {
                Text(title).opacity(isLoading ? 0 : 1)
                if isLoading { ProgressView().tint(role == .primary ? .black : .white) }
            }
            .font(.system(size: 18, weight: .bold))
            .frame(maxWidth: .infinity, minHeight: 56)
            .foregroundStyle(fg)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(bg))
        }
        .buttonStyle(PressableStyle(scale: 0.97))
        .disabled(isLoading)
    }

    private var bg: Color {
        if !isEnabled { return Theme.well }
        switch role { case .primary: return .white; default: return Theme.raised }
    }
    private var fg: Color {
        if !isEnabled { return Theme.faint }
        switch role { case .primary: return .black; case .secondary: return .white; case .destructive: return Theme.danger }
    }
}

/// Range pills ("Today / This Week…"). Solid: white selected, grey others.
struct Pills<T: Hashable>: View {
    let options: [(T, String)]
    @Binding var selection: T
    var quiet = false

    var body: some View {
        HStack(spacing: quiet ? 10 : 8) {
            ForEach(options.indices, id: \.self) { i in
                let (value, label) = options[i]
                let on = value == selection
                Button {
                    Haptics.selection()
                    withAnimation(.easeOut(duration: 0.15)) { selection = value }
                } label: {
                    Text(label)
                        .font(.system(size: 15, weight: .semibold))
                        .padding(.horizontal, 14)
                        .frame(height: quiet ? 32 : 43)
                        .foregroundStyle(on ? (quiet ? .white : .black) : Theme.faint)
                        .background(Capsule().fill(on ? (quiet ? Theme.raised : .white) : (quiet ? .clear : Theme.raised)))
                }
                .buttonStyle(PressableStyle())
            }
        }
    }
}

struct EmojiCircle: View {
    let emoji: String
    let colorHex: String
    var size: CGFloat = 46
    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.5))
            .frame(width: size, height: size)
            .background(Circle().fill(Color(hex: colorHex).tint()))
    }
}

/// Emoji + name pill. Selected: tinted fill, 2pt accent border, accent label.
struct CategoryChip: View {
    let category: ExpenseCategory
    let selected: Bool
    var action: () -> Void

    var body: some View {
        let color = Color(hex: category.colorHex)
        Button(action: {
            Haptics.selection()
            action()
        }) {
            HStack(spacing: 8) {
                Text(category.emoji).font(.system(size: 18))
                Text(category.name).font(.system(size: 15, weight: .semibold)).lineLimit(1)
            }
            .padding(.leading, 16).padding(.trailing, 18)
            .frame(height: 43)
            .foregroundStyle(selected ? color : Theme.faint)
            .background(Capsule().fill(selected ? color.opacity(0.14) : Theme.raised))
            .overlay(Capsule().strokeBorder(selected ? color : .clear, lineWidth: 2))
        }
        .buttonStyle(PressableStyle())
    }
}

/// 3×4 keypad with large rounded dark keys. Holding backspace clears.
struct NumPad: View {
    var showsDecimal = true
    var keyHeight: CGFloat = 63
    var leftAccessory: AnyView? = nil
    var onKey: (String) -> Void
    var onBackspace: () -> Void
    var onClear: () -> Void

    private let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "extra", "0", "back"]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3), spacing: 6) {
            ForEach(keys, id: \.self) { k in
                switch k {
                case "extra":
                    if showsDecimal { key(".") { onKey(".") } } else { leftAccessory ?? AnyView(Color.clear.frame(height: keyHeight)) }
                case "back":
                    key(nil, systemImage: "arrow.left") { onBackspace() }
                        .simultaneousGesture(LongPressGesture(minimumDuration: 0.45).onEnded { _ in
                            Haptics.soft()
                            onClear()
                        })
                default:
                    key(k) { onKey(k) }
                }
            }
        }
    }

    private func key(_ label: String?, systemImage: String? = nil, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Group {
                if let systemImage { Image(systemName: systemImage).font(.system(size: 24, weight: .medium)) }
                else { Text(label ?? "").font(.system(size: 28, weight: .medium)) }
            }
            .frame(maxWidth: .infinity, minHeight: keyHeight)
            .foregroundStyle(.white)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.raised))
        }
        .buttonStyle(KeyStyle())
    }
}

private struct KeyStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white.opacity(configuration.isPressed ? 0.12 : 0))
                .animation(.easeOut(duration: configuration.isPressed ? 0 : 0.2), value: configuration.isPressed))
    }
}

/// Settings row as its own rounded card: title (+ grey subtitle) left,
/// grey value + › right.
struct SettingsRow<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    var value: String? = nil
    var destructive = false
    var chevron = true
    var action: (() -> Void)? = nil
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        let content = HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 16, weight: .semibold)).foregroundStyle(destructive ? Theme.danger : .white)
                if let subtitle { Text(subtitle).font(.tFootnote).foregroundStyle(Theme.sub).multilineTextAlignment(.leading) }
            }
            Spacer(minLength: 8)
            trailing()
            if let value { Text(value + (chevron && action != nil ? " ›" : "")).font(.tBody).foregroundStyle(Theme.sub).lineLimit(1) }
            else if chevron && action != nil { Image(systemName: "chevron.right").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.sub) }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .frame(minHeight: 58)
        .background(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous).fill(Theme.card))
        .contentShape(Rectangle())

        if let action {
            Button(action: action) { content }.buttonStyle(RowPressStyle())
        } else { content }
    }
}

extension SettingsRow where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, value: String? = nil, destructive: Bool = false, chevron: Bool = true, action: (() -> Void)? = nil) {
        self.init(title: title, subtitle: subtitle, value: value, destructive: destructive, chevron: chevron, action: action, trailing: { EmptyView() })
    }
}

struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous)
                .fill(.white.opacity(configuration.isPressed ? 0.06 : 0)))
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    var hint: String? = nil
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: title).padding(.bottom, hint == nil ? 4 : 0)
            if let hint { Text(hint).font(.tFootnote).foregroundStyle(Theme.sub).padding(.bottom, 6) }
            content()
        }
        .padding(.top, 26)
    }
}

/// Input field style used in sheets.
struct FieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.tBody)
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.raised))
    }
}

extension View {
    func fieldStyle() -> some View { modifier(FieldStyle()) }
}

struct EmptyStateView: View {
    let emoji: String
    let title: String
    var message: String? = nil
    var body: some View {
        VStack(spacing: 6) {
            Text(emoji).font(.system(size: 44))
            Text(title).font(.tHeadline).padding(.top, 6)
            if let message { Text(message).font(.tFootnote).foregroundStyle(Theme.sub).multilineTextAlignment(.center) }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 56)
    }
}
