import Foundation

struct Stats {
    var count = 0
    var spent = 0.0
    var credit = 0.0
    var net: Double { spent - credit }
    var days = 1
    var avgPerDay: Double { spent / Double(max(days, 1)) }
    var categories: [CategoryTotal] = []
    var buckets: [Bucket] = []
    var top: [Entry] = []
}
