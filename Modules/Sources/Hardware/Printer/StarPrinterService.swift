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

    /// Identifies the active discovery session. A stream only tears down the session it started, so a
    /// stale stream finishing can never clear a session that a later `discover()` call replaced it with.
    private var discoverySessionID = 0

    /// Maps a discovered device's identifier to its underlying `StarPrinter`,
    /// so we can connect by `PrinterDevice` without exposing StarIO10 types.
    private var discoveredPrinters: [String: StarPrinter] = [:]

    /// Serialises access to the discovery-session state and `discoveredPrinters`, which are touched from
    /// both StarIO10 callbacks and the discovery/connection methods. Mirrors `StripeCardReaderService`.
    private let lock = NSLock()

    private let connectionStatusSubject = CurrentValueSubject<PrinterConnectionStatus, Never>(.idle)
    public var connectionStatusPublisher: AnyPublisher<PrinterConnectionStatus, Never> {
        connectionStatusSubject.eraseToAnyPublisher()
    }

    public func discover() -> AsyncThrowingStream<PrinterDevice, Error> {
        AsyncThrowingStream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }
            Task {
                do {
                    let discovery = try StarDeviceDiscoveryManagerFactory.create(interfaceTypes: [.bluetooth, .bluetoothLE])

                    let delegate = StarDiscoveryDelegate(
                        onFind: { [weak self] starPrinter in
                            let device = PrinterDevice(
                                id: starPrinter.connectionSettings.identifier,
                                name: starPrinter.connectionSettings.identifier
                            )
                            self?.storeDiscoveredPrinter(starPrinter, for: device)
                            continuation.yield(device)
                        },
                        onFinish: {
                            continuation.finish()
                        }
                    )
                    discovery.delegate = delegate
                    discovery.discoveryTime = Constants.discoveryTimeInMilliseconds

                    // Register (taking over from any in-flight session) before starting discovery, so the
                    // termination handler also tears down state if `startDiscovery()` throws.
                    let sessionID = self.beginDiscoverySession(manager: discovery, delegate: delegate)
                    continuation.onTermination = { [weak self] _ in
                        self?.endDiscoverySession(sessionID)
                    }

                    try discovery.startDiscovery()
                } catch {
                    DDLogError("🖨️ Printer discovery failed: \(error.localizedDescription)")
                    continuation.finish(throwing: StarPrinterError.discoveryFailure)
                }
            }
        }
    }

    public func stopDiscovery() {
        lock.lock()
        let manager = discoveryManager
        lock.unlock()
        manager?.stopDiscovery()
    }

    public func connect(to device: PrinterDevice) async throws {
        lock.lock()
        let discoveredPrinter = discoveredPrinters[device.id]
        lock.unlock()

        guard let starPrinter = discoveredPrinter else {
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

    func storeDiscoveredPrinter(_ starPrinter: StarPrinter, for device: PrinterDevice) {
        lock.lock()
        discoveredPrinters[device.id] = starPrinter
        lock.unlock()
    }

    /// Registers a new discovery session, stopping any in-flight one, and returns its identifier.
    func beginDiscoverySession(manager: StarDeviceDiscoveryManager, delegate: StarDiscoveryDelegate) -> Int {
        lock.lock()
        let previousManager = discoveryManager
        let previousDelegate = discoveryDelegate
        discoverySessionID += 1
        let sessionID = discoverySessionID
        discoveryManager = manager
        discoveryDelegate = delegate
        lock.unlock()

        // Keep the previous delegate alive while stopping its manager, then release it outside the lock.
        // StarIO10 holds the manager's delegate weakly, so releasing it under the lock could deallocate it
        // and re-enter the lock via its stream's termination handler, deadlocking a non-recursive `NSLock`.
        withExtendedLifetime(previousDelegate) {
            previousManager?.stopDiscovery()
        }
        return sessionID
    }

    /// Tears down a discovery session, but only while it is still the active one.
    func endDiscoverySession(_ sessionID: Int) {
        lock.lock()
        guard sessionID == discoverySessionID else {
            lock.unlock()
            return
        }
        let manager = discoveryManager
        discoveryManager = nil
        discoveryDelegate = nil
        lock.unlock()

        manager?.stopDiscovery()
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
