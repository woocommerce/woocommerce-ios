import Combine
import struct Yosemite.PrinterDevice
import enum Yosemite.PrinterConnectionStatus
import enum Yosemite.ReceiptPrinterAction
import protocol Yosemite.StoresManager
import protocol PointOfSale.POSReceiptPrinterProviding

/// App-target backend for POS receipt printing.
///
/// Bridges the POS module's `POSReceiptPrinterProviding` facade to Yosemite by dispatching
/// `ReceiptPrinterAction`, so the POS module reaches printers without importing Hardware.
final class POSReceiptPrinterService: POSReceiptPrinterProviding {
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    var connectionStatusPublisher: AnyPublisher<PrinterConnectionStatus, Never> {
        var publisher: AnyPublisher<PrinterConnectionStatus, Never>?
        let action = ReceiptPrinterAction.connectionStatusPublisher { publisher = $0 }
        stores.dispatch(action)
        return publisher ?? Empty(completeImmediately: false).eraseToAnyPublisher()
    }

    func discover() -> AsyncThrowingStream<PrinterDevice, Error> {
        var stream: AsyncThrowingStream<PrinterDevice, Error>?
        let action = ReceiptPrinterAction.discover { stream = $0 }
        stores.dispatch(action)
        return stream ?? AsyncThrowingStream { $0.finish() }
    }

    func stopDiscovery() {
        stores.dispatch(ReceiptPrinterAction.stopDiscovery)
    }

    func connect(to printer: PrinterDevice) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let action = ReceiptPrinterAction.connect(printer: printer) { result in
                continuation.resume(with: result)
            }
            stores.dispatch(action)
        }
    }

    func disconnect() async {
        await withCheckedContinuation { continuation in
            let action = ReceiptPrinterAction.disconnect {
                continuation.resume()
            }
            stores.dispatch(action)
        }
    }
}
