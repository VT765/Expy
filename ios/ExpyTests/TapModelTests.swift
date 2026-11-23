import Testing
@testable import Expy

@MainActor
struct TapModelTests {
    private let hdfc = Account(id: "acc_hdfc", name: "HDFC", kind: .bank, openingBalancePaise: 0, openingDate: .distantPast, order: 0)
    private let cash = Account(id: "acc_cash", name: "Cash", kind: .cash, openingBalancePaise: 0, openingDate: .distantPast, order: 1)

    @Test func kindPillsToggleBackToDebit() {
        let m = TapModel()
        m.toggle(.transfer)
        #expect(m.kind == .transfer)
        m.toggle(.credit)
        #expect(m.kind == .credit)
        m.toggle(.credit)
        #expect(m.kind == .expense)
    }

    @Test func transferNeedsTwoDifferentAccounts() {
        let m = TapModel()
        m.amount = "5000"
        m.kind = .transfer
        #expect(m.canSave(from: hdfc, to: cash))
        #expect(!m.canSave(from: hdfc, to: hdfc))
        #expect(!m.canSave(from: hdfc, to: nil))
        m.kind = .expense
        #expect(m.canSave(from: hdfc, to: nil))
        m.amount = ""
        #expect(!m.canSave(from: hdfc, to: nil))
    }
}
