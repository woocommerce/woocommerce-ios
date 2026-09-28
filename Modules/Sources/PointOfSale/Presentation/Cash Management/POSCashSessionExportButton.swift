import SwiftUI
import UIKit

/// Add to the trailing content of a closed session's page header.
struct POSCashSessionExportButton: View {
    let session: POSCashSession

    @State private var sharedFile: SharedFile?
    @State private var temporaryFileURL: URL?
    @State private var showsExportError = false

    var body: some View {
        Button {
            do {
                let file = try POSCashSessionCSVExporter.writeFile(for: session)
                temporaryFileURL = file
                sharedFile = SharedFile(url: file)
            } catch {
                showsExportError = true
            }
        } label: {
            Label(Localization.export, systemImage: "square.and.arrow.up")
        }
        .buttonStyle(POSInfoCardButtonStyle(size: .compact, variant: .default))
        .disabled(session.closedAt == nil)
        .accessibilityIdentifier("pos-cash-session-export")
        .sheet(item: $sharedFile, onDismiss: removeTemporaryFile) { file in
            POSCashSessionShareSheet(fileURL: file.url)
        }
        .alert(Localization.exportFailed, isPresented: $showsExportError) {
            Button(Localization.dismiss, role: .cancel) {}
        } message: {
            Text(Localization.exportFailedMessage)
        }
    }

    private func removeTemporaryFile() {
        guard let temporaryFileURL else { return }
        try? FileManager.default.removeItem(at: temporaryFileURL.deletingLastPathComponent())
        self.temporaryFileURL = nil
    }
}

private struct SharedFile: Identifiable {
    let id = UUID()
    let url: URL
}

private struct POSCashSessionShareSheet: UIViewControllerRepresentable {
    let fileURL: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = controller.view
        controller.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        controller.popoverPresentationController?.permittedArrowDirections = []
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

private extension POSCashSessionExportButton {
    enum Localization {
        static let export = NSLocalizedString("pos.cashSession.detail.export", value: "Export", comment: "Export a closed cash session summary")
        static let exportFailed = NSLocalizedString("pos.cashSession.detail.exportFailed", value: "Could not export session",
                                                  comment: "Cash session export error heading")
        static let exportFailedMessage = NSLocalizedString("pos.cashSession.detail.exportFailedMessage",
                                                         value: "Try exporting the session again.", comment: "Cash session export error message")
        static let dismiss = NSLocalizedString("pos.cashSession.detail.exportDismiss", value: "OK", comment: "Dismiss the cash session export error")
    }
}
