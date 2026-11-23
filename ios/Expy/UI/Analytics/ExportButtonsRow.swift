import SwiftUI

/// Excel and CSV export of the current period.
struct ExportButtonsRow: View {
    let range: DateRange
    @State private var exporting: ExportKind?
    @State private var shareURL: ShareItem?

    var body: some View {
        HStack(spacing: 6) {
            ExportButton(title: "Excel", busy: exporting == .xlsx) { export(.xlsx) }
            ExportButton(title: "CSV", busy: exporting == .csv) { export(.csv) }
        }
        .sheet(item: $shareURL) { ShareSheet(items: [$0.url]) }
    }

    private func export(_ kind: ExportKind) {
        exporting = kind
        Task {
            defer { exporting = nil }
            do { shareURL = ShareItem(url: try Exporter.export(kind, range: range)) }
            catch { ToastCenter.shared.error(error.localizedDescription) }
        }
    }
}
