import Foundation
import SwiftData
import Testing
@testable import Expy

/// Builds a store exactly as older builds wrote it (SchemaV1), then opens it
/// with the migration plan the app uses and checks every converted value.
@MainActor
struct MigrationTests {
    private func makeV1Store() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("v1-\(UUID().uuidString).store")
        let schema = Schema(versionedSchema: SchemaV1.self)
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
        let ctx = container.mainContext
        let day = TestData.date(2026, 11, 10)
        let food = SchemaV1.Entry(id: "tx_food", type: "expense", amount: 80.1, currency: "INR", amountInBase: 80.1,
                                  categoryId: "cat_food", note: "Panipuri", date: day, createdAt: day, updatedAt: day)
        food.accountId = "acc_cash"
        ctx.insert(food)
        ctx.insert(SchemaV1.Entry(id: "tx_usd", type: "expense", amount: 12, currency: "USD", amountInBase: 1003.55,
                                  categoryId: "cat_subscriptions", note: "iCloud", date: day, createdAt: day, updatedAt: day))
        ctx.insert(SchemaV1.Entry(id: "tx_salary", type: "credit", amount: 85_000, currency: "INR", amountInBase: 85_000,
                                  categoryId: "cat_other", note: "", date: day, createdAt: day, updatedAt: day))
        ctx.insert(SchemaV1.Account(id: "acc_cash", name: "Cash", kind: "cash", openingBalance: 2_000.5, openingDate: day, order: 0))
        ctx.insert(SchemaV1.Budget(id: "budget_total", categoryId: nil, amount: 40_000, updatedAt: day))
        ctx.insert(SchemaV1.AppSettings(baseCurrency: "INR", cycleStartDay: 5, rateOverrides: ["USD": 83.6]))
        ctx.insert(SchemaV1.OutboxItem(key: "k", collection: "transactions", payload: Data(), updatedAt: 1))
        try ctx.save()
        return url
    }

    @Test func v1StoreMigratesToCurrentSchema() throws {
        let url = try makeV1Store()
        let container = try ModelContainer(for: Persistence.schema, migrationPlan: ExpyMigrationPlan.self,
                                           configurations: ModelConfiguration(schema: Persistence.schema, url: url))
        let ctx = container.mainContext
        let entries = Dictionary(uniqueKeysWithValues: try ctx.fetch(FetchDescriptor<Entry>()).map { ($0.id, $0) })

        #expect(entries.count == 3)
        #expect(entries["tx_food"]?.amountPaise == 8_010)
        #expect(entries["tx_food"]?.kind == .expense)
        #expect(entries["tx_food"]?.accountId == "acc_cash")
        #expect(entries["tx_salary"]?.kind == .credit)
        #expect(entries["tx_salary"]?.amountPaise == 8_500_000)
        // Foreign-currency entries keep the rupee value and note the original.
        #expect(entries["tx_usd"]?.amountPaise == 100_355)
        #expect(entries["tx_usd"]?.note == "iCloud (USD 12)")

        let cash = try ctx.fetch(FetchDescriptor<Account>()).first
        #expect(cash?.kind == .cash)
        #expect(cash?.openingBalancePaise == 200_050)
        #expect(try ctx.fetch(FetchDescriptor<Budget>()).first?.amountPaise == 4_000_000)
        #expect(try ctx.fetch(FetchDescriptor<AppSettings>()).first?.cycleStartDay == 5)
        #expect(try ctx.fetch(FetchDescriptor<RecurringRule>()).isEmpty)
    }

    @Test func v3CategoriesBecomeDebitCategories() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("v3-\(UUID().uuidString).store")
        do {
            let schema = Schema(versionedSchema: SchemaV3.self)
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
            container.mainContext.insert(SchemaV3.ExpenseCategory(id: "cat_food", name: "Food", emoji: "🍔", colorHex: "#FF6B6B",
                                                                  order: 0, updatedAt: .now))
            try container.mainContext.save()
        }
        let container = try ModelContainer(for: Persistence.schema, migrationPlan: ExpyMigrationPlan.self,
                                           configurations: ModelConfiguration(schema: Persistence.schema, url: url))
        let food = try container.mainContext.fetch(FetchDescriptor<ExpenseCategory>()).first
        #expect(food?.name == "Food")
        #expect(food?.kind == .expense)
    }
}
