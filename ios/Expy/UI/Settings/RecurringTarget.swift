import Foundation

/// What the recurring editor opens on: a new rule (optionally copied from
/// an entry) or an existing one.
enum RecurringTarget: Identifiable {
    case new(template: Entry?)
    case existing(RecurringRule)

    var id: String {
        switch self {
        case .new(let e): "new-\(e?.id ?? "")"
        case .existing(let r): r.id
        }
    }
}
