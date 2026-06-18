import Combine
import Foundation
import Hardware
import Networking
import Storage

/// Routes receipt-printer discovery and connection through an injected Hardware discovery service.
///
/// Owns the only reference to the printer SDK in the Yosemite layer, so callers (the app target
/// and the POS module) interact with printers without importing Hardware.
public final class ReceiptPrinterStore: Store {
    private let printerDiscoveryService: PrinterDiscoveryService

    public init(dispatcher: Dispatcher,
                storageManager: StorageManagerType,
                network: Network,
                printerDiscoveryService: PrinterDiscoveryService) {
        self.printerDiscoveryService = printerDiscoveryService
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    public override func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: ReceiptPrinterAction.self)
    }

    public override func onAction(_ action: Action) {
        guard let action = action as? ReceiptPrinterAction else {
            assertionFailure("\(String(describing: self)) received an unsupported action")
            return
        }

        switch action {
        case let .connectionStatusPublisher(onPublisher):
            onPublisher(printerDiscoveryService.connectionStatusPublisher)
        case let .discover(onStream):
            onStream(printerDiscoveryService.discover())
        case .stopDiscovery:
            printerDiscoveryService.stopDiscovery()
        case let .connect(printer, completion):
            connect(to: printer, completion: completion)
        case let .disconnect(completion):
            disconnect(completion: completion)
        }
    }
}

private extension ReceiptPrinterStore {
    func connect(to printer: PrinterDevice, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await printerDiscoveryService.connect(to: printer)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func disconnect(completion: @escaping () -> Void) {
        Task {
            await printerDiscoveryService.disconnect()
            completion()
        }
    }
}
