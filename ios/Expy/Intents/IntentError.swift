import AppIntents
import SwiftData

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case invalidAmount
    var localizedStringResource: LocalizedStringResource { "Enter an amount greater than 0." }
}
