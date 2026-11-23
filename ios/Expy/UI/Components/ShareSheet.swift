import SwiftUI

/// System share sheet for a file created on demand (Save to Files, AirDrop,
/// Mail, Numbers…). `ShareLink` needs the file before the tap, so this bridges
/// `UIActivityViewController`.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
