import UIKit
import Combine
import Hardware
import PointOfSale

/// A receipt printer service that renders receipts to PDF and presents a share sheet.
/// Always reports as "connected" — no hardware discovery or pairing needed.
/// Conforms to `POSReceiptPrinterProviding` so it can be swapped with `StarReceiptPrinterService`.
///
final class PDFReceiptPrinterService: POSReceiptPrinterProviding {

    private let statusSubject = CurrentValueSubject<DeviceStatus, Never>(.connected)

    var statusPublisher: AnyPublisher<DeviceStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }

    func discover() -> AsyncThrowingStream<PrinterDevice, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(PrinterDevice(id: "pdf-printer", name: "PDF Printer"))
            continuation.finish()
        }
    }

    func stopDiscovery() { }

    func connect(to printer: PrinterDevice) { }

    func disconnect() async { }

    @MainActor
    func printReceipt(content: ReceiptContent) async throws {
        let pdfData = renderPDF(from: content)
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("receipt-\(UUID().uuidString).pdf")
        try pdfData.write(to: tempURL)
        presentShareSheet(for: tempURL)
    }
}

// MARK: - PDF Rendering
private extension PDFReceiptPrinterService {
    func renderPDF(from content: ReceiptContent) -> Data {
        let renderer = ReceiptRenderer(content: content)
        renderer.configureFormatterForPrinting()

        let pageSize = content.preferredPageSizeForPrinting
        let pageRect = CGRect(origin: .zero, size: pageSize)

        let pdfData = NSMutableData()
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, nil)

        let numberOfPages = renderer.numberOfPages
        for pageIndex in 0..<max(numberOfPages, 1) {
            UIGraphicsBeginPDFPage()
            renderer.drawPage(at: pageIndex, in: pageRect)
        }

        UIGraphicsEndPDFContext()
        return pdfData as Data
    }
}

// MARK: - Share Sheet Presentation
private extension PDFReceiptPrinterService {
    @MainActor
    func presentShareSheet(for fileURL: URL) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            DDLogError("⚠️ [PDFPrinter] Could not find root view controller to present share sheet")
            return
        }

        // Walk to the topmost presented controller
        var presenter = rootVC
        while let presented = presenter.presentedViewController {
            presenter = presented
        }

        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)

        // iPad requires popover configuration
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.bounds.midY,
                width: 0,
                height: 0
            )
        }

        presenter.present(activityVC, animated: true)
    }
}
