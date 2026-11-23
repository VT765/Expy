import Foundation

// Stable ids so seeding on launch and restoring backups never duplicate defaults.
enum Defaults {
    static let otherCategoryId = "cat_other"
    /// Fallback credit category ("Other income"); like "Other", it can't be deleted.
    static let otherCreditCategoryId = "inc_other"
    static let cashAccountId = "acc_cash"
    /// Transfers have no category.
    static let transferCategoryId = ""

    static let categories: [(id: String, name: String, emoji: String, color: String)] = [
        ("cat_food", "Food", "🍔", "#FF6B6B"),
        ("cat_transport", "Transport", "🚕", "#FFB340"),
        ("cat_shopping", "Shopping", "🛍️", "#E8D25A"),
        ("cat_subscriptions", "Subscriptions", "😎", "#FF7A59"),
        ("cat_bills", "Bills", "🧾", "#8AB4F8"),
        ("cat_groceries", "Groceries", "🛒", "#5FD38D"),
        ("cat_health", "Health", "💊", "#FF5C8A"),
        ("cat_entertainment", "Entertainment", "🎬", "#B48CFF"),
        ("cat_personal_care", "Personal Care", "💇", "#FF9F7A"),
        ("cat_travel", "Travel", "✈️", "#5AC8FA"),
        (otherCategoryId, "Other", "✨", "#9DB0C4"),
    ]

    /// Default credit (income) categories.
    static let creditCategories: [(id: String, name: String, emoji: String, color: String)] = [
        ("inc_salary", "Salary", "💼", "#5FD38D"),
        ("inc_refund", "Refund", "↩️", "#5AC8FA"),
        ("inc_cashback", "Cashback", "💸", "#E8D25A"),
        ("inc_interest", "Interest", "🏦", "#8AB4F8"),
        ("inc_freelance", "Freelance", "🧑‍💻", "#B48CFF"),
        ("inc_gift", "Gift", "🎁", "#FF5C8A"),
        (otherCreditCategoryId, "Other income", "✨", "#9DB0C4"),
    ]

    /// Every default category with its kind, in display order per kind.
    static var allCategories: [(kind: TransactionKind, order: Int, id: String, name: String, emoji: String, color: String)] {
        categories.enumerated().map { (.expense, $0.offset, $0.element.id, $0.element.name, $0.element.emoji, $0.element.color) }
            + creditCategories.enumerated().map { (.credit, $0.offset, $0.element.id, $0.element.name, $0.element.emoji, $0.element.color) }
    }

    /// Where entries go when their category is deleted.
    static func fallbackCategoryId(for kind: TransactionKind) -> String {
        kind == .credit ? otherCreditCategoryId : otherCategoryId
    }

    static func isFallback(_ id: String) -> Bool { id == otherCategoryId || id == otherCreditCategoryId }

    static let categoryColors = [
        "#FF6B6B", "#FF7A59", "#FF9F7A", "#FFB340", "#E8D25A", "#5FD38D",
        "#5AC8FA", "#8AB4F8", "#B48CFF", "#FF5C8A", "#9DB0C4", "#D9D9D9",
    ]

    static let epoch = Date(timeIntervalSince1970: 0)
}
