#if DEBUG
import Foundation

/// Launch-argument hooks used to put screens into specific states for
/// simulator screenshots (e.g. `-demoAmount 250 -demoSaved`). Debug only.
enum Demo {
    static let args = ProcessInfo.processInfo.arguments
    static func value(_ flag: String) -> String? {
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
    static func has(_ flag: String) -> Bool { args.contains(flag) }
}
#endif
