import Testing
@testable import Expy

struct CategoryGuesserTests {
    private let valid = Set(Defaults.categories.map(\.id))

    @Test(arguments: [("Swiggy", "cat_food"), ("Uber India", "cat_transport"), ("BLINKIT", "cat_groceries"),
                      ("Netflix.com", "cat_subscriptions"), ("IRCTC ticket", "cat_travel"), ("Random shop", "cat_other")])
    func guessesFromKeywords(_ narration: String, _ expected: String) {
        #expect(CategoryGuesser.guess(narration, history: [:], valid: valid) == expected)
    }

    @Test func pastEntriesWinOverKeywords() {
        #expect(CategoryGuesser.guess("Swiggy", history: ["swiggy": "cat_entertainment"], valid: valid) == "cat_entertainment")
    }

    @Test func ignoresHistoryForDeletedCategories() {
        #expect(CategoryGuesser.guess("Swiggy", history: ["swiggy": "cat_gone"], valid: valid) == "cat_food")
    }

    @Test(arguments: [("NEFT CR-ACME PAYROLL-SALARY NOV", "inc_salary"), ("REFUND MYNTRA", "inc_refund"),
                      ("Credit Interest Capitalised", "inc_interest"), ("UPI cashback", "inc_cashback"), ("IMPS from Rahul", "inc_other")])
    func guessesCreditCategories(_ narration: String, _ expected: String) {
        let credit = Set(Defaults.creditCategories.map(\.id))
        #expect(CategoryGuesser.guess(narration, kind: .credit, history: [:], valid: credit) == expected)
    }
}
