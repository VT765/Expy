import SwiftData
import SwiftUI

/// Quick add: "How much?", big amount, category chips (or "To" accounts for a
/// transfer), date pills, note, account + Credit/Transfer, numpad, Save.
struct TapView: View {
    @Query(filter: #Predicate<ExpenseCategory> { $0.deletedAt == nil }, sort: \ExpenseCategory.order)
    private var categories: [ExpenseCategory]
    @Query(filter: #Predicate<Account> { $0.deletedAt == nil }, sort: \Account.order) private var accounts: [Account]
    @AppStorage("lastAccount") private var accountId = Defaults.cashAccountId
    @AppStorage("lastCategory") private var categoryId = "cat_food"
    @AppStorage("lastCreditCategory") private var creditCategoryId = "inc_salary"
    @AppStorage("lastTransferTo") private var toAccountId = ""
    @State private var model = TapModel()

    // Vertical layout measured from the reference (iPhone 15 Pro, points below
    // the status bar). GeometryReader is needed to scale gaps and keys down on
    // shorter screens.
    private static let referenceHeight = 711.0

    /// Credit shows the credit categories; debit (and transfer) the expense ones.
    private var shownCategories: [ExpenseCategory] { categories.filter { $0.isCredit == model.credit } }
    private var selected: ExpenseCategory? {
        let id = model.credit ? creditCategoryId : categoryId
        return shownCategories.first { $0.id == id } ?? shownCategories.first
    }
    private var selectedAccount: Account? { accounts.first { $0.id == accountId } ?? accounts.first }
    /// Transfer destination: the last one used, else the first other account.
    private var toAccount: Account? {
        let others = accounts.filter { $0.id != selectedAccount?.id }
        return others.first { $0.id == toAccountId } ?? others.first
    }

    var body: some View {
        GeometryReader { geo in
            let k = min(1, geo.size.height / Self.referenceHeight)
            VStack(spacing: 0) {
                AmountHeader(model: model).frame(height: 90 * k)
                Rectangle().fill(Theme.well).frame(height: 1).padding(.horizontal, Theme.gutter)
                Group {
                    if model.isTransfer {
                        TransferTargetRow(accounts: accounts, fromId: selectedAccount?.id, selectedId: toAccount?.id, select: selectTarget)
                    } else {
                        CategoryChipsRow(categories: shownCategories, selectedId: selected?.id, select: selectCategory)
                    }
                }
                .padding(.top, 39 * k)
                DatePillsRow(model: model).padding(.top, 29 * k)
                NoteRow(model: model, recentNotes: model.recentNotes(categoryId: model.isTransfer ? Defaults.transferCategoryId : selected?.id))
                    .frame(height: 24).padding(.top, 10 * k)
                AccountKindRow(accounts: accounts, accountId: $accountId, selected: selectedAccount, model: model)
                    .padding(.top, 22 * k)
                // Keys take whatever height is left, so Save never runs under the tab bar.
                GeometryReader { pad in
                    NumPad(keyHeight: min(63, max(40, (pad.size.height - 18) / 4)),
                           onKey: model.press, onBackspace: model.backspace, onClear: model.clear)
                        .padding(.horizontal, 16)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .frame(maxHeight: 63 * 4 + 18)
                .padding(.top, 10 * k)
                PrimaryButton(title: model.justSaved ? "Saved" : "Save", icon: model.justSaved ? "checkmark" : nil, action: save)
                    .disabled(!model.canSave(from: selectedAccount, to: toAccount) && !model.justSaved)
                    .allowsHitTesting(!model.justSaved)
                    .padding(.horizontal, Theme.gutter)
                    .padding(.top, 20 * k)
                    .padding(.bottom, 14)
            }
        }
        .background(Theme.canvas)
        // Fixed-height keypad: allow larger text, but not sizes that would overflow keys.
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .onReceive(NotificationCenter.default.publisher(for: .prefillEntry)) { n in
            if let p = n.object as? Prefill { applyPrefill(p) }
        }
        .onAppear(perform: appeared)
    }

    private func selectCategory(_ id: String) {
        if model.credit { creditCategoryId = id } else { categoryId = id }
    }
    private func selectTarget(_ id: String) { toAccountId = id }

    private func save() {
        guard let selected else { return }
        model.save(category: selected, account: selectedAccount, toAccount: toAccount)
    }

    private func applyPrefill(_ p: Prefill) {
        if let id = model.apply(p, categories: categories) { selectCategory(id) }
    }

    private func appeared() {
        if let p = Prefill.pending {
            applyPrefill(p)
            Prefill.pending = nil
        }
        #if DEBUG
        model.applyDemoState()
        #endif
    }
}
