import Foundation

/// Category suggestions from narration keywords and past entries.
enum CategoryGuesser {
    private static let rules: [(String, [String])] = [
        ("cat_food", ["swiggy", "zomato", "restaurant", "cafe", "domino", "mcdonald", "kfc", "pizza", "starbucks", "eatsure", "food", "bakery", "hotel"]),
        ("cat_groceries", ["bigbasket", "blinkit", "zepto", "dmart", "grofers", "instamart", "reliance fresh", "jiomart", "more retail", "grocery", "kirana"]),
        ("cat_transport", ["uber", "ola", "rapido", "metro", "fastag", "petrol", "fuel", "hpcl", "bpcl", "indian oil", "iocl", "parking", "toll"]),
        ("cat_travel", ["irctc", "makemytrip", "goibibo", "indigo", "air india", "vistara", "akasa", "spicejet", "oyo", "airbnb", "cleartrip", "redbus", "ixigo"]),
        ("cat_shopping", ["amazon", "flipkart", "myntra", "ajio", "meesho", "nykaa", "tata cliq", "croma", "decathlon", "ikea", "lifestyle"]),
        ("cat_subscriptions", ["netflix", "spotify", "prime", "hotstar", "youtube", "apple.com", "google play", "icloud", "jiocinema", "sonyliv", "zee5"]),
        ("cat_bills", ["electricity", "bescom", "mseb", "tneb", "airtel", "jio", "vodafone", "bsnl", "broadband", "gas", "water", "recharge", "bill", "rent", "emi", "insurance", "lic"]),
        ("cat_health", ["pharmacy", "apollo", "medplus", "hospital", "clinic", "1mg", "pharmeasy", "netmeds", "diagnostic", "lab"]),
        ("cat_entertainment", ["bookmyshow", "pvr", "inox", "cinepolis", "steam", "playstation"]),
        ("cat_personal_care", ["salon", "spa", "urban company", "urbanclap", "barber", "parlour"]),
        // Credits
        ("inc_salary", ["salary", "payroll", "sal cr", "stipend"]),
        ("inc_refund", ["refund", "reversal", "rev-", "returned"]),
        ("inc_cashback", ["cashback", "cash back", "reward"]),
        ("inc_interest", ["interest", "int.pd", "int pd", "int.cr", "dividend"]),
    ]

    /// `valid` holds the category ids of the row's kind; unmatched rows fall back to that kind's "Other".
    static func guess(_ narration: String, kind: TransactionKind = .expense, history: [String: String], valid: Set<String>) -> String {
        let n = narration.lowercased()
        if let past = history[n], valid.contains(past) { return past }
        for (id, words) in rules where valid.contains(id) && words.contains(where: n.contains) { return id }
        return Defaults.fallbackCategoryId(for: kind)
    }
}
