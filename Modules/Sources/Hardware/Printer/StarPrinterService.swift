import Foundation
import Combine
import StarIO10

/// Concrete `PrinterDiscoveryService` backed by the Star Micronics StarIO10 SDK.
///
/// Discovers Star printers over Bluetooth and manages the connection lifecycle. The mapping
/// from a discovered `StarPrinter` to its Hardware-domain `PrinterDevice` is kept here,
/// so callers connect by `PrinterDevice` without ever touching StarIO10 types.
public final class StarPrinterService: PrinterDiscoveryService {
    public init() {
        // Opt out of StarIO10's diagnostic-info upload, which is enabled by default.
        StarIO10DiagInfoUpload.shared.isEnabled = false
    }

    private var printer: StarPrinter?
    private var discoveryManager: StarDeviceDiscoveryManager?
    // swiftlint:disable:next weak_delegate
    private var discoveryDelegate: StarDiscoveryDelegate?

    /// Maps a discovered device's identifier to its underlying `StarPrinter`,
    /// so we can connect by `PrinterDevice` without exposing StarIO10 types.
    private var discoveredPrinters: [String: StarPrinter] = [:]

    private let connectionStatusSubject = CurrentValueSubject<PrinterConnectionStatus, Never>(.idle)
    public var connectionStatusPublisher: AnyPublisher<PrinterConnectionStatus, Never> {
        connectionStatusSubject.eraseToAnyPublisher()
    }

    public func discover() -> AsyncThrowingStream<PrinterDevice, Error> {
        AsyncThrowingStream { [weak self] continuation in
            Task {
                do {
                    let discovery = try StarDeviceDiscoveryManagerFactory.create(interfaceTypes: [.bluetooth, .bluetoothLE])
                    self?.discoveryManager = discovery

                    let delegate = StarDiscoveryDelegate(
                        onFind: { [weak self] starPrinter in
                            let device = PrinterDevice(
                                id: starPrinter.connectionSettings.identifier,
                                name: starPrinter.connectionSettings.identifier
                            )
                            self?.discoveredPrinters[device.id] = starPrinter
                            continuation.yield(device)
                        },
                        onFinish: {
                            continuation.finish()
                        }
                    )
                    self?.discoveryDelegate = delegate
                    discovery.delegate = delegate

                    discovery.discoveryTime = Constants.discoveryTimeInMilliseconds
                    try discovery.startDiscovery()

                    continuation.onTermination = { [weak self] _ in
                        discovery.stopDiscovery()
                        self?.discoveryDelegate = nil
                    }
                } catch {
                    DDLogError("🖨️ Printer discovery failed: \(error.localizedDescription)")
                    continuation.finish(throwing: StarPrinterError.discoveryFailure)
                }
            }
        }
    }

    public func stopDiscovery() {
        discoveryManager?.stopDiscovery()
    }

    public func connect(to device: PrinterDevice) async throws {
        guard let starPrinter = discoveredPrinters[device.id] else {
            DDLogError("🖨️ No discovered printer matches device id \(device.id)")
            throw StarPrinterError.printerNotFound
        }

        connectionStatusSubject.send(.connecting)
        do {
            starPrinter.printerDelegate = self
            try await starPrinter.open()
            printer = starPrinter
            connectionStatusSubject.send(.connected)
            DDLogInfo("🖨️ Connected to printer \(device.id)")
        } catch {
            connectionStatusSubject.send(.disconnected)
            DDLogError("🖨️ Printer connection failed: \(error.localizedDescription)")
            throw error
        }
    }

    public func disconnect() async {
        connectionStatusSubject.send(.disconnecting)
        await printer?.close()
        printer = nil
        connectionStatusSubject.send(.disconnected)
    }
}

private extension StarPrinterService {
    enum Constants {
        static let discoveryTimeInMilliseconds = 30000
    }
}

/// Bridges StarIO10 discovery callbacks into the discovery `AsyncThrowingStream`.
private final class StarDiscoveryDelegate: NSObject, StarDeviceDiscoveryManagerDelegate {
    private let onFind: (StarPrinter) -> Void
    private let onFinish: () -> Void

    init(onFind: @escaping (StarPrinter) -> Void, onFinish: @escaping () -> Void) {
        self.onFind = onFind
        self.onFinish = onFinish
    }

    func manager(_ manager: any StarDeviceDiscoveryManager, didFind printer: StarPrinter) {
        DDLogInfo("🖨️ Found printer \(printer.connectionSettings.identifier)")
        onFind(printer)
    }

    func managerDidFinishDiscovery(_ manager: any StarDeviceDiscoveryManager) {
        DDLogInfo("🖨️ Finished printer discovery")
        onFinish()
    }
}

extension StarPrinterService: PrinterDelegate {
    public func printer(_ printer: StarPrinter, communicationErrorDidOccur error: any Error) {
        DDLogError("🖨️ Printer communication error: \(error.localizedDescription)")
    }

    public func printerIsReady(_ printer: StarPrinter) {
        DDLogInfo("🖨️ Printer is ready")
    }

    public func printerDidHaveError(_ printer: StarPrinter) {
        DDLogError("🖨️ Printer reported an error")
    }

    public func printerIsPaperReady(_ printer: StarPrinter) {
        DDLogInfo("🖨️ Printer paper is ready")
    }

    public func printerIsPaperNearEmpty(_ printer: StarPrinter) {
        DDLogInfo("🖨️ Printer paper is near empty")
    }

    public func printerIsPaperEmpty(_ printer: StarPrinter) {
        DDLogInfo("🖨️ Printer paper is empty")
    }

    public func printerIsCoverOpen(_ printer: StarPrinter) {
        DDLogInfo("🖨️ Printer cover is open")
    }

    public func printerIsCoverClose(_ printer: StarPrinter) {
        DDLogInfo("🖨️ Printer cover is closed")
    }
}

enum StarPrinterError: Error {
    case discoveryFailure
    case printerNotFound
}
