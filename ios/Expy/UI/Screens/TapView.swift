import SwiftData
import SwiftUI

/// Quick add: "How much?", big amount, category chips, date pills, note,
/// Credit toggle, numpad, Save.
struct TapView: View {
    @Query(filter: #Predicate<ExpenseCategory> { $0.deletedAt == nil }, sort: \ExpenseCategory.order)
    private var categories: [ExpenseCategory]
    @Query private var settingsList: [AppSettings]

    @State private var amount = ""
    @AppStorage("lastCategory") private var categoryId = "cat_food"
    @State private var dateMode = DateMode.today
    @State private var pickedDay = Date()
    @State private var showDatePicker = false
    @State private var note = ""
    @State private var noteOpen = false
    @State private var credit = false
    @State private var currency: String?
    @State private var showCurrency = false
    @State private var savePulse = false
    @FocusState private var noteFocused: Bool
    @Environment(\.showSettings) private var showSettings

    enum DateMode { case today, yesterday, pick }

    private var base: String { settingsList.first?.baseCurrency ?? "INR" }
    private var activeCurrency: String { currency ?? base }
    private var value: Double { (Double(amount) ?? 0).rounded(toPlaces: 2) }
    private var selected: ExpenseCategory? { categories.first { $0.id == categoryId } ?? categories.first }

    var body: some View {
        VStack(spacing: 0) {
            amountHeader
            Rectangle().fill(Theme.well).frame(height: 1).padding(.horizontal, Theme.gutter)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories) { c in
                            CategoryChip(category: c, selected: c.id == selected?.id) { categoryId = c.id }.id(c.id)
                        }
                    }
                    .padding(.horizontal, Theme.gutter)
                    .padding(.vertical, 18)
                }
                .onAppear { proxy.scrollTo(selected?.id, anchor: .center) }
                .onChange(of: categoryId) { withAnimation { proxy.scrollTo(categoryId, anchor: .center) } }
            }

            datePills
            noteAndCredit

            NumPad(onKey: press, onBackspace: { if !amount.isEmpty { amount.removeLast() } }, onClear: { amount = "" })
                .padding(.horizontal, 16)
                .padding(.top, 8)

            PrimaryButton(title: "Save", action: save)
                .disabled(value <= 0)
                .padding(.horizontal, Theme.gutter)
                .padding(.top, 18)
                .padding(.bottom, 12)
        }
        .background(Theme.canvas)
        .sheet(isPresented: $showCurrency) {
            CurrencyPicker(selected: activeCurrency) { code in
                currency = code == base ? nil : code
                showCurrency = false
            }
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickSheet(date: $pickedDay) {
                dateMode = .pick
                showDatePicker = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .prefillEntry)) { n in
            if let p = n.object as? Prefill { apply(p) }
        }
        .onAppear {
            if let p = Prefill.pending { apply(p); Prefill.pending = nil }
        }
    }

    // MARK: - Sections

    private var amountHeader: some View {
        let shown = Self.display(amount)
        let size: CGFloat = shown.count > 10 ? 34 : shown.count > 7 ? 40 : 46
        return ZStack(alignment: .top) {
            VStack(spacing: 6) {
                Text(credit ? "How much came in?" : "How much?").font(.tBody).foregroundStyle(Theme.sub)
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Button { showCurrency = true } label: {
                        Text(Currencies.symbol(activeCurrency))
                            .font(.system(size: activeCurrency == "INR" ? size : size * 0.6, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Currency \(activeCurrency). Tap to change")
                    Text((credit && value > 0 ? "+" : "") + shown)
                        .font(.system(size: size, weight: .bold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                .scaleEffect(savePulse ? 0.9 : 1)
                .opacity(savePulse ? 0 : 1)
                Text(activeCurrency != base && value > 0 ? "≈ \(Fmt.money(DataStore.shared.toBase(value, activeCurrency).value, base))" : " ")
                    .font(.tFootnote).foregroundStyle(Theme.sub)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            HStack {
                SyncBadge()
                Spacer()
                Button { showSettings() } label: {
                    Image(systemName: "gearshape").font(.system(size: 20)).foregroundStyle(Theme.faint).frame(width: 44, height: 44)
                }
                .accessibilityLabel("Settings")
            }
            .padding(.horizontal, 8)
        }
        .frame(maxHeight: .infinity)
    }

    private var datePills: some View {
        HStack(spacing: 10) {
            pill("Today", on: dateMode == .today) { dateMode = .today }
            pill("Yesterday", on: dateMode == .yesterday) { dateMode = .yesterday }
            pill(dateMode == .pick ? Fmt.shortDate.string(from: pickedDay) : "Pick date", on: dateMode == .pick) { showDatePicker = true }
        }
    }

    private func pill(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            Text(title).font(.system(size: 15, weight: .semibold))
                .padding(.horizontal, 14).frame(height: 32)
                .foregroundStyle(on ? .white : Theme.faint)
                .background(Capsule().fill(on ? Theme.raised : .clear))
        }
        .buttonStyle(PressableStyle())
    }

    private var noteAndCredit: some View {
        HStack(spacing: 12) {
            if noteOpen {
                TextField("Add a note", text: $note)
                    .focused($noteFocused)
                    .submitLabel(.done)
                    .onSubmit { noteFocused = false; if note.trimmingCharacters(in: .whitespaces).isEmpty { noteOpen = false } }
                    .font(.tBody)
                    .padding(.horizontal, 14).frame(height: 40)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.raised))
            } else {
                Button("+ add note") {
                    noteOpen = true
                    noteFocused = true
                }
                .font(.tBody).foregroundStyle(Theme.sub)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button {
                Haptics.selection()
                credit.toggle()
            } label: {
                Text("Credit").font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 16).frame(height: 40)
                    .foregroundStyle(credit ? .black : Theme.faint)
                    .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(credit ? .white : Theme.raised))
            }
            .buttonStyle(PressableStyle())
        }
        .padding(.horizontal, Theme.gutter)
        .frame(height: 52)
    }

    // MARK: - Actions

    private func press(_ k: String) { amount = Self.press(amount, k) }

    private func save() {
        guard value > 0, let cat = selected else { return }
        let day: Date = switch dateMode {
        case .today: Date()
        case .yesterday: Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        case .pick: Self.withCurrentTime(pickedDay)
        }
        let missing = DataStore.shared.toBase(value, activeCurrency).missingRate
        let e = DataStore.shared.addEntry(type: credit ? "credit" : "expense", amount: value, currency: activeCurrency,
                                          categoryId: cat.id, note: note, date: day)
        Haptics.success()
        withAnimation(.easeOut(duration: 0.18)) { savePulse = true }
        ToastCenter.shared.show("Saved \(credit ? "+" : "")\(Fmt.money(e.amount, e.currency)) · \(cat.name)")
        if missing { ToastCenter.shared.error("No \(activeCurrency) rate yet. Set one in Settings → Exchange rates.") }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            amount = ""; note = ""; noteOpen = false; credit = false; dateMode = .today; currency = nil
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { savePulse = false }
        }
    }

    private func apply(_ p: Prefill) {
        if let a = p.amount, a > 0 { amount = Self.trimmed(a) }
        if let t = p.type { credit = t == "credit" }
        if let n = p.note, !n.isEmpty { note = n; noteOpen = true }
        if let c = p.category?.lowercased(), let match = categories.first(where: { $0.id == c || $0.name.lowercased() == c }) {
            categoryId = match.id
        }
    }

    // MARK: - Amount string helpers

    static func press(_ cur: String, _ k: String) -> String {
        if k == "." { return cur.contains(".") ? cur : (cur.isEmpty ? "0" : cur) + "." }
        let parts = cur.split(separator: ".", omittingEmptySubsequences: false)
        if parts.count == 2 { return parts[1].count >= 2 ? cur : cur + k }
        if cur == "0" || cur.isEmpty { return k }
        return cur.count >= 9 ? cur : cur + k
    }

    static func display(_ cur: String) -> String {
        if cur.isEmpty { return "0" }
        let parts = cur.split(separator: ".", omittingEmptySubsequences: false)
        let grouped = Fmt.number(Double(parts[0]) ?? 0)
        return parts.count == 2 ? "\(grouped).\(parts[1])" : grouped
    }

    static func trimmed(_ v: Double) -> String {
        let r = v.rounded(toPlaces: 2)
        return r == r.rounded() ? String(Int(r)) : String(r)
    }

    static func withCurrentTime(_ day: Date) -> Date {
        let c = Calendar.current
        let t = c.dateComponents([.hour, .minute, .second], from: Date())
        return c.date(bySettingHour: t.hour ?? 12, minute: t.minute ?? 0, second: t.second ?? 0, of: day) ?? day
    }
}

extension Double {
    func rounded(toPlaces p: Int) -> Double {
        let m = pow(10, Double(p))
        return (self * m).rounded() / m
    }
}

/// Small sync status badge (top-left of the Tap screen). Tap to sync now.
struct SyncBadge: View {
    @State private var sync = SyncEngine.shared
    var body: some View {
        if sync.state != .local {
            Button { sync.sync() } label: {
                HStack(spacing: 6) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "cloud").font(.system(size: 17))
                        Circle().fill(dot).frame(width: 7, height: 7).overlay(Circle().stroke(.black, lineWidth: 1.5)).offset(x: 2, y: -1)
                    }
                    if sync.state != .synced { Text(sync.label).font(.system(size: 12, weight: .medium)) }
                }
                .foregroundStyle(Theme.faint)
                .frame(height: 44)
                .padding(.horizontal, 6)
            }
            .accessibilityLabel("Sync status: \(sync.label)")
        }
    }

    private var dot: Color {
        switch sync.state {
        case .synced: Color(hex: "#5FD38D")
        case .pending: Color(hex: "#FFB340")
        case .syncing: Theme.sub
        default: Theme.danger
        }
    }
}

struct DatePickSheet: View {
    @Binding var date: Date
    var done: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            DatePicker("Date", selection: $date, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(.white)
            PrimaryButton(title: "Use this date", action: done)
        }
        .padding(Theme.gutter)
        .presentationDetents([.medium, .large])
        .presentationBackground(Theme.card)
    }
}

/// Prefill payload from App Intents / URLs (expy://add?amount=&cat=&type=&note=).
struct Prefill {
    var amount: Double?
    var category: String?
    var type: String?
    var note: String?
    static var pending: Prefill?

    init?(url: URL) {
        guard let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems, !items.isEmpty else { return nil }
        func q(_ k: String) -> String? { items.first { $0.name == k }?.value }
        amount = q("amount").flatMap(Double.init)
        category = q("cat")
        type = q("type").map { $0.lowercased().hasPrefix("c") ? "credit" : "expense" }
        note = q("note")
    }
}

extension Notification.Name {
    static let prefillEntry = Notification.Name("expy.prefillEntry")
}

/// Lets any screen open Settings via @Environment(\.showSettings).
struct ShowSettingsAction {
    let action: () -> Void
    func callAsFunction() { action() }
}

private struct ShowSettingsKey: EnvironmentKey {
    static let defaultValue = ShowSettingsAction {}
}

extension EnvironmentValues {
    var showSettings: ShowSettingsAction {
        get { self[ShowSettingsKey.self] }
        set { self[ShowSettingsKey.self] = newValue }
    }
}
