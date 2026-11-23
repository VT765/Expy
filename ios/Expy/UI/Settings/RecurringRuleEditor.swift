import SwiftData
import SwiftUI

/// Create or edit a recurring rule: debit/credit/transfer, amount, name,
/// category (or From/To accounts), account, frequency, first date, optional
/// end date, reminder, pause, delete.
struct RecurringRuleEditor: View {
    let target: RecurringTarget
    @Query(filter: #Predicate<ExpenseCategory> { $0.deletedAt == nil }, sort: \ExpenseCategory.order)
    private var categories: [ExpenseCategory]
    @Query(filter: #Predicate<Account> { $0.deletedAt == nil }, sort: \Account.order) private var accounts: [Account]
    @Environment(\.dismiss) private var dismiss

    @State private var draft = RecurringEngine.Draft()
    @State private var amount: Double?
    @State private var hasEnd = false
    @State private var endDate = Date.now
    @State private var paused = false
    @State private var confirmDelete = false

    private var rule: RecurringRule? {
        if case .existing(let r) = target { return r }
        return nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Pills(options: kindOptions, selection: $draft.kind)
                    TitledGroup(title: "Amount") {
                        HStack(spacing: 8) {
                            Text("₹").font(.app(20, .bold)).foregroundStyle(Theme.sub)
                            TextField("0", value: $amount, format: .number.precision(.fractionLength(0...2)))
                                .keyboardType(.decimalPad).font(.app(20, .bold))
                        }
                        .padding(.horizontal, 16).frame(minHeight: 52)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.raised))
                    }
                    TitledGroup(title: "Name") {
                        TextField("e.g. Rent, Netflix, Car EMI", text: $draft.note).fieldStyle()
                    }
                    if draft.kind == .transfer {
                        AccountMenuField(title: "From", selection: $draft.accountId, accounts: accounts)
                        AccountMenuField(title: "To", selection: $draft.toAccountId, accounts: accounts)
                    } else {
                        TitledGroup(title: "Category") {
                            ScrollView(.horizontal) {
                                HStack(spacing: 10) {
                                    ForEach(categories.filter { $0.isCredit == (draft.kind == .credit) }) { c in
                                        CategoryChip(category: c, selected: c.id == draft.categoryId) { draft.categoryId = c.id }
                                    }
                                }
                            }
                            .scrollIndicators(.hidden)
                        }
                        AccountMenuField(title: draft.kind == .credit ? "Credited to" : "Paid from", selection: $draft.accountId,
                                         accounts: accounts, allowsNone: true)
                    }
                    TitledGroup(title: "Repeats") {
                        Pills(options: RecurrenceFrequency.allCases.map { ($0, $0.label) }, selection: $draft.frequency)
                    }
                    DatePicker(rule == nil ? "First date" : "Starts", selection: $draft.startDate, displayedComponents: .date)
                        .tint(.white).font(.tBody)
                    if rule == nil && draft.startDate < Calendar.current.startOfDay(for: .now) {
                        Text("Past dates are added to History right away.").font(.tFootnote).foregroundStyle(Theme.sub)
                    }
                    Toggle("Ends", isOn: $hasEnd).tint(Theme.positive).font(.tBody)
                    if hasEnd {
                        DatePicker("Last date", selection: $endDate, in: draft.startDate..., displayedComponents: .date)
                            .tint(.white).font(.tBody)
                    }
                    Toggle(isOn: $draft.remind) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reminder").font(.tBody)
                            Text("A notification at 9 AM on the day").font(.tFootnote).foregroundStyle(Theme.sub)
                        }
                    }
                    .tint(Theme.positive)
                    if let rule {
                        Toggle("Paused", isOn: $paused).tint(Theme.positive).font(.tBody)
                        Text("Next: \(rule.nextDate.formatted(date: .abbreviated, time: .omitted)). Stopping a rule keeps the entries it already added.")
                            .font(.tFootnote).foregroundStyle(Theme.sub)
                        Button("Delete recurring", role: .destructive) { confirmDelete = true }
                            .font(.tBodySemibold).foregroundStyle(Theme.danger)
                    }
                }
                .padding(Theme.gutter)
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: rule == nil ? "Add recurring" : "Save", action: save)
                    .disabled(!isValid)
                    .padding(.horizontal, Theme.gutter).padding(.bottom, 8)
            }
            .navigationTitle(rule == nil ? "New recurring" : "Edit recurring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: cancel).tint(Theme.sub) } }
            .alert("Delete \(rule?.note ?? "recurring")?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive, action: delete)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Entries it already added stay in History.")
            }
        }
        .presentationBackground(Theme.card)
        .onAppear(perform: load)
        .onChange(of: draft.kind) { _, _ in matchCategoryToKind() }
    }

    private var kindOptions: [(TransactionKind, String)] {
        [(.expense, "Debit"), (.credit, "Credit")] + (accounts.count > 1 ? [(.transfer, "Transfer")] : [])
    }

    private func matchCategoryToKind() {
        guard draft.kind != .transfer else { return }
        let options = categories.filter { $0.isCredit == (draft.kind == .credit) }
        if !options.contains(where: { $0.id == draft.categoryId }) {
            draft.categoryId = options.first?.id ?? Defaults.fallbackCategoryId(for: draft.kind)
        }
    }

    private var isValid: Bool {
        guard (amount ?? 0) > 0 else { return false }
        if draft.kind == .transfer {
            return draft.accountId != nil && draft.toAccountId != nil && draft.accountId != draft.toAccountId
        }
        return true
    }

    private func load() {
        switch target {
        case .existing(let r):
            draft = .init(kind: r.kind, amount: r.amount, categoryId: r.categoryId, accountId: r.accountId, toAccountId: r.toAccountId,
                          note: r.note, frequency: r.frequency, startDate: r.startDate, endDate: r.endDate, remind: r.remind)
            hasEnd = r.endDate != nil
            endDate = r.endDate ?? .now
            paused = r.isPaused
        case .new(let e?):
            // "Make recurring" from an entry: same details, starting one month after it.
            draft = .init(kind: e.kind, amount: e.amount, categoryId: e.isTransfer ? Defaults.otherCategoryId : e.categoryId,
                          accountId: e.accountId, toAccountId: e.toAccountId, note: e.note,
                          startDate: Calendar.current.date(byAdding: .month, value: 1, to: e.date) ?? .now)
        case .new(nil):
            draft.accountId = accounts.first?.id
            draft.categoryId = categories.first?.id ?? Defaults.otherCategoryId
        }
        amount = draft.amount > 0 ? draft.amount : nil
    }

    private func cancel() { dismiss() }

    private func save() {
        var d = draft
        d.amount = amount ?? 0
        d.endDate = hasEnd ? endDate : nil
        d.note = d.note.trimmingCharacters(in: .whitespaces)
        RecurringEngine.save(d, rule: rule)
        if let rule, rule.isPaused != paused { RecurringEngine.setPaused(rule, paused) }
        if d.remind { Task { await Notifier.requestPermission() } }
        Haptics.success()
        dismiss()
    }

    private func delete() {
        if let rule { RecurringEngine.delete(rule) }
        dismiss()
    }
}
