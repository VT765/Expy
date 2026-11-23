import Foundation

// Same stable ids as shared/defaults.js so devices never duplicate defaults.
enum Defaults {
    static let otherCategoryId = "cat_other"

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

    static let categoryColors = [
        "#FF6B6B", "#FF7A59", "#FF9F7A", "#FFB340", "#E8D25A", "#5FD38D",
        "#5AC8FA", "#8AB4F8", "#B48CFF", "#FF5C8A", "#9DB0C4", "#D9D9D9",
    ]

    static let epoch = Date(timeIntervalSince1970: 0)
}
