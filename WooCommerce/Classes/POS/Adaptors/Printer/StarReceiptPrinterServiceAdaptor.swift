import Foundation
import Combine
import StarIO10
import Hardware
import PointOfSale

/// Adaptor that wraps `StarReceiptPrinterService` and conforms to `POSReceiptPrinterProviding`.
/// Maps between StarIO10's `StarPrinter` and POS module's `PrinterDevice`.
///
final class StarReceiptPrinterServiceAdaptor: POSReceiptPrinterProviding {

    private let starService: StarReceiptPrinterService

    /// Keeps a mapping from PrinterDevice ID → StarPrinter so we can connect by ID.
    private var discoveredPrinters: [String: StarPrinter] = [:]

    init(starService: StarReceiptPrinterService = StarReceiptPrinterService()) {
        self.starService = starService
    }

    var statusPublisher: AnyPublisher<DeviceStatus, Never> {
        starService.statusPublisher
    }

    func discover() -> AsyncThrowingStream<PrinterDevice, Error> {
        let starStream = starService.discover()
        return AsyncThrowingStream { continuation in
            Task { [weak self] in
                do {
                    for try await starPrinter in starStream {
                        let device = PrinterDevice(
                            id: starPrinter.connectionSettings.identifier,
                            name: starPrinter.connectionSettings.identifier
                        )
                        self?.discoveredPrinters[device.id] = starPrinter
                        continuation.yield(device)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func stopDiscovery() {
        starService.stopDiscovery()
    }

    func connect(to printer: PrinterDevice) {
        guard let starPrinter = discoveredPrinters[printer.id] else {
            DDLogError("🖨️ [Adaptor] No StarPrinter found for device ID: \(printer.id)")
            return
        }
        starService.connect(to: starPrinter)
    }

    func disconnect() async {
        await starService.disconnect()
        discoveredPrinters.removeAll()
    }

    func printReceipt(content: ReceiptContent) async throws {
        try await starService.printReceipt(content: content)
    }
}
