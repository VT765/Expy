import SwiftData
import SwiftUI

struct HistoryFilters: Equatable {
    var categoryIds: Set<String> = []
    var type = "all" // all | expense | credit
    var minAmount = ""
    var maxAmount = ""
    var from: Date?
    var to: Date?
    var query = ""

    var isActive: Bool {
        !categoryIds.isEmpty || type != "all" || !minAmount.isEmpty || !maxAmount.isEmpty || from != nil || to != nil
            || !query.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func matches(_ e: Entry, categoryName: String) -> Bool {
        if !categoryIds.isEmpty && !categoryIds.contains(e.categoryId) { return false }
        if type != "all" && e.type != type { return false }
        if let min = Double(minAmount), e.amountInBase < min { return false }
        if let max = Double(maxAmount), e.amountInBase > max { return false }
        if let from, e.date < Calendar.current.startOfDay(for: from) { return false }
        if let to, e.date >= Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: to))! { return false }
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty && !e.note.lowercased().contains(q) && !categoryName.lowercased().contains(q) { return false }
        return true
    }
}

/// "Expenses": grouped by day with day totals, swipe to delete, tap to edit,
/// sticky Total footer. List is lazily rendered (virtualized) by SwiftUI.
struct HistoryView: View {
    @Query(filter: #Predicate<Entry> { $0.deletedAt == nil }, sort: \Entry.date, order: .reverse)
    private var entries: [Entry]
    @Query private var allCategories: [ExpenseCategory]
    @Query private var settingsList: [AppSettings]

    @AppStorage("historyRange") private var range = PeriodKind.month.rawValue
    @State private var filters = HistoryFilters()
    @State private var showFilters = false
    @State private var editing: Entry?

    private var base: String { settingsList.first?.baseCurrency ?? "INR" }
    private var cycleDay: Int { settingsList.first?.cycleStartDay ?? 1 }

    private struct DayGroup: Identifiable {
        let day: Date
        var items: [Entry]
        var total: Double
        var id: Date { day }
    }

    private var categoryById: [String: ExpenseCategory] { Dictionary(allCategories.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a }) }

    private func category(_ id: String) -> ExpenseCategory? { categoryById[id] ?? categoryById[Defaults.otherCategoryId] }

    private var groups: (days: [DayGroup], total: Double, count: Int) {
        let r = Periods.range(PeriodKind(rawValue: range) ?? .month, cycleDay: cycleDay)
        let cats = categoryById
        var days: [DayGroup] = []
        var total = 0.0
        var count = 0
        let cal = Calendar.current
        for e in entries where r.contains(e.date) && filters.matches(e, categoryName: cats[e.categoryId]?.name ?? "") {
            let d = cal.startOfDay(for: e.date)
            if days.last?.day != d { days.append(DayGroup(day: d, items: [], total: 0)) }
            days[days.count - 1].items.append(e)
            days[days.count - 1].total += e.signedBase
            total += e.signedBase
            count += 1
        }
        return (days, total, count)
    }

    var body: some View {
        let g = groups
        VStack(spacing: 0) {
            ZStack {
                Text("Expenses").font(.tTitle)
                HStack {
                    Spacer()
                    Button { showFilters = true } label: {
                        Image(systemName: "slider.horizontal.3").font(.system(size: 22, weight: .medium))
                            .frame(width: 44, height: 44)
                            .overlay(alignment: .topTrailing) {
                                if filters.isActive { Circle().fill(Theme.danger).frame(width: 9, height: 9).offset(x: -4, y: 6) }
                            }
                    }
                    .foregroundStyle(.white)
                    .accessibilityLabel("Filters")
                }
            }
            .padding(.horizontal, Theme.gutter - 8)
            .frame(height: 56)

            ScrollView(.horizontal, showsIndicators: false) {
                Pills(options: [("today", "Today"), ("week", "This Week"), ("month", "This Month"), ("all", "All")], selection: $range)
                    .padding(.horizontal, Theme.gutter)
            }
            .padding(.bottom, 8)

            if g.count == 0 {
                Spacer()
                EmptyStateView(emoji: filters.isActive ? "🔍" : "🧾",
                               title: filters.isActive ? "No matches" : "Nothing here yet",
                               message: filters.isActive ? "Nothing fits these filters in this range." : "Log your first expense from the Tap tab.")
                if filters.isActive {
                    Button("Clear filters") { filters = HistoryFilters() }.font(.tBodySemibold).padding(.top, -24)
                }
                Spacer()
            } else {
                List {
                    ForEach(g.days) { day in
                        Section {
                            ForEach(day.items) { e in
                                row(e)
                                    .listRowBackground(Theme.canvas)
                                    .listRowInsets(EdgeInsets(top: 0, leading: Theme.gutter, bottom: 0, trailing: Theme.gutter))
                                    .listRowSeparatorTint(Theme.well)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) { delete(e) } label: { Label("Delete", systemImage: "trash") }
                                    }
                            }
                        } header: {
                            HStack {
                                Text(Fmt.dayHeader(day.day).uppercased()).tracking(1)
                                Spacer()
                                Text(Fmt.money(day.total, base))
                            }
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.faint)
                            .padding(.top, 14)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListHeaderHeight, 1)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if g.count > 0 {
                HStack {
                    Text("Total").font(.system(size: 18, weight: .semibold)).foregroundStyle(Theme.faint)
                    Spacer()
                    Text(Fmt.money(g.total, base)).font(.system(size: 25, weight: .bold)).monospacedDigit()
                }
                .padding(.horizontal, Theme.gutter)
                .frame(height: 68)
                .background(Theme.card.overlay(alignment: .top) { Rectangle().fill(Theme.well).frame(height: 0.5) })
            }
        }
        .background(Theme.canvas)
        .sheet(isPresented: $showFilters) { FilterSheet(filters: $filters) }
        .sheet(item: $editing) { e in EditEntrySheet(entry: e) }
    }

    private func row(_ e: Entry) -> some View {
        let c = category(e.categoryId)
        return Button { editing = e } label: {
            HStack(spacing: 14) {
                EmojiCircle(emoji: c?.emoji ?? "✨", colorHex: c?.colorHex ?? "#9DB0C4")
                VStack(alignment: .leading, spacing: 2) {
                    Text(c?.name ?? "Other").font(.tHeadline).lineLimit(1)
                    Text(e.note.isEmpty ? " " : e.note).font(.tBody).foregroundStyle(Theme.sub).lineLimit(1)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Fmt.money(e.signedBase, base)).font(.tHeadline).monospacedDigit()
                    Text((e.currency != base ? "\(Fmt.money(e.amount, e.currency)) · " : "") + Fmt.time.string(from: e.date))
                        .font(.tFootnote).foregroundStyle(Theme.sub).monospacedDigit()
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 72)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func delete(_ e: Entry) {
        DataStore.shared.deleteEntry(e)
        Haptics.soft()
        ToastCenter.shared.show("Entry deleted", action: ("Undo", { DataStore.shared.restoreEntry(e) }))
    }
}

// MARK: - Edit

struct EditEntrySheet: View {
    let entry: Entry
    @Query(filter: #Predicate<ExpenseCategory> { $0.deletedAt == nil }, sort: \ExpenseCategory.order)
    private var categories: [ExpenseCategory]
    @Environment(\.dismiss) private var dismiss

    @State private var amount = ""
    @State private var currency = "INR"
    @State private var type = "expense"
    @State private var categoryId = ""
    @State private var date = Date()
    @State private var note = ""
    @State private var showCurrency = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 8) {
                        Button("\(Currencies.symbol(currency)) \(currency)") { showCurrency = true }
                            .font(.tBodySemibold).foregroundStyle(.white)
                            .padding(.horizontal, 16).frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.raised))
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 22, weight: .bold))
                            .padding(.horizontal, 16).frame(height: 48)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.raised))
                    }
                    Pills(options: [("expense", "Expense"), ("credit", "Credit")], selection: $type)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(categories) { c in CategoryChip(category: c, selected: c.id == categoryId) { categoryId = c.id } }
                        }
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Date & time").font(.tFootnote).foregroundStyle(Theme.sub)
                        DatePicker("", selection: $date).labelsHidden().tint(.white)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Note").font(.tFootnote).foregroundStyle(Theme.sub)
                        TextField("Add a note", text: $note).fieldStyle()
                    }
                }
                .padding(Theme.gutter)
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    PrimaryButton(title: "Delete", role: .destructive) {
                        DataStore.shared.deleteEntry(entry)
                        ToastCenter.shared.show("Entry deleted", action: ("Undo", { DataStore.shared.restoreEntry(entry) }))
                        dismiss()
                    }
                    .frame(width: 120)
                    PrimaryButton(title: "Save", action: save)
                }
                .padding(.horizontal, Theme.gutter).padding(.bottom, 8)
            }
            .navigationTitle("Edit entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.tint(Theme.sub) } }
        }
        .presentationDetents([.large])
        .presentationBackground(Theme.card)
        .onAppear {
            amount = TapView.trimmed(entry.amount)
            currency = entry.currency
            type = entry.type
            categoryId = entry.categoryId
            date = entry.date
            note = entry.note
        }
        .sheet(isPresented: $showCurrency) {
            CurrencyPicker(selected: currency) { currency = $0; showCurrency = false }
        }
    }

    private func save() {
        guard let a = Double(amount.replacingOccurrences(of: ",", with: "")), a > 0 else {
            ToastCenter.shared.error("Enter an amount greater than 0")
            return
        }
        DataStore.shared.updateEntry(entry, type: type, amount: a, currency: currency, categoryId: categoryId, note: note, date: date)
        ToastCenter.shared.show("Changes saved")
        dismiss()
    }
}

// MARK: - Filters

struct FilterSheet: View {
    @Binding var filters: HistoryFilters
    @State private var draft = HistoryFilters()
    @State private var useFrom = false
    @State private var useTo = false
    @Query(filter: #Predicate<ExpenseCategory> { $0.deletedAt == nil }, sort: \ExpenseCategory.order)
    private var categories: [ExpenseCategory]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(Theme.faint)
                        TextField("Search notes", text: $draft.query)
                    }
                    .fieldStyle()

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: "Type")
                        Pills(options: [("all", "All"), ("expense", "Expenses"), ("credit", "Credits")], selection: $draft.type)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: "Categories")
                        FlowLayout(spacing: 8) {
                            ForEach(categories) { c in
                                CategoryChip(category: c, selected: draft.categoryIds.contains(c.id)) {
                                    if draft.categoryIds.contains(c.id) { draft.categoryIds.remove(c.id) } else { draft.categoryIds.insert(c.id) }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: "Amount range")
                        HStack(spacing: 12) {
                            TextField("Min", text: $draft.minAmount).keyboardType(.decimalPad).fieldStyle()
                            Text("–").foregroundStyle(Theme.sub)
                            TextField("Max", text: $draft.maxAmount).keyboardType(.decimalPad).fieldStyle()
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        SectionLabel(text: "Date range")
                        dateRow("From", on: $useFrom, date: Binding(get: { draft.from ?? Date() }, set: { draft.from = $0 }))
                        dateRow("To", on: $useTo, date: Binding(get: { draft.to ?? Date() }, set: { draft.to = $0 }))
                    }
                }
                .padding(Theme.gutter)
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "Apply") {
                    if !useFrom { draft.from = nil }
                    if !useTo { draft.to = nil }
                    filters = draft
                    dismiss()
                }
                .padding(.horizontal, Theme.gutter).padding(.bottom, 8)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() }.tint(Theme.sub) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Reset") { draft = HistoryFilters(); useFrom = false; useTo = false }.tint(Theme.sub)
                }
            }
        }
        .presentationBackground(Theme.card)
        .onAppear {
            draft = filters
            useFrom = filters.from != nil
            useTo = filters.to != nil
        }
    }

    private func dateRow(_ title: String, on: Binding<Bool>, date: Binding<Date>) -> some View {
        HStack {
            Toggle(title, isOn: on).tint(.white).font(.tBody)
            if on.wrappedValue { DatePicker("", selection: date, displayedComponents: .date).labelsHidden() }
        }
        .padding(.horizontal, 16).frame(minHeight: 48)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.raised))
    }
}

/// Simple wrapping layout for chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
        return CGSize(width: width == .infinity ? x : width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let size = s.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}

// MARK: - Currency picker

struct CurrencyPicker: View {
    let selected: String
    var onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(Currencies.all) { c in
                Button { onSelect(c.code) } label: {
                    HStack(spacing: 12) {
                        Text(c.symbol).font(.tBodySemibold).frame(width: 40)
                        Text(c.name).font(.tBody)
                        Spacer()
                        Text(c.code).font(.tFootnote).foregroundStyle(Theme.sub)
                        Image(systemName: "checkmark").opacity(c.code == selected ? 1 : 0)
                    }
                    .foregroundStyle(.white)
                }
                .listRowBackground(Theme.raised)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() }.tint(Theme.sub) } }
        }
        .presentationBackground(Theme.card)
    }
}
