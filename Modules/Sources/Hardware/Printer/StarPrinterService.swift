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

    /// Whether a `connect(to:)` call is currently in flight. Set while a connection is being established so
    /// overlapping `connect` calls are rejected, keeping us the delegate of at most one printer at a time.
    private var isConnecting = false

    /// The in-flight discovery session, if any. A session uses identity (`===`) to tell whether it is
    /// still current, so a superseded or cancelled session never mistakes itself for the active one.
    private var activeSession: DiscoverySession?

    /// Maps a discovered device's identifier to its underlying `StarPrinter`,
    /// so we can connect by `PrinterDevice` without exposing StarIO10 types.
    private var discoveredPrinters: [String: StarPrinter] = [:]

    /// Guards reads and writes of `activeSession`, `discoveredPrinters`, `printer`, and `isConnecting`, which
    /// are touched from both StarIO10 callback threads and the discovery/connection methods. Held only for the
    /// field access: the lock is non-recursive, so call-outs to the SDK (and finishing a stream, which can
    /// re-enter via a termination handler) are always done after unlocking.
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
            // Install synchronously while the stream is being built, so overlapping `discover()` calls
            // install in call order and a `stopDiscovery()` issued right after sees the active session.
            self.startDiscovery(streaming: continuation)
        }
    }

    public func stopDiscovery() {
        lock.lock()
        let manager = activeSession?.manager
        lock.unlock()
        manager?.stopDiscovery()
    }

    public func connect(to device: PrinterDevice) async throws {
        lock.lock()
        if isConnecting {
            lock.unlock()
            DDLogError("🖨️ A connection is already in progress; ignoring connect for \(device.id)")
            throw PrinterError.connectionInProgress
        }
        isConnecting = true
        let discoveredPrinter = discoveredPrinters[device.id]
        let existing = printer
        lock.unlock()

        defer {
            lock.lock()
            isConnecting = false
            lock.unlock()
        }

        guard let starPrinter = discoveredPrinter else {
            DDLogError("🖨️ No discovered printer matches device id \(device.id)")
            throw PrinterError.printerNotFound
        }

        // Tear down any current connection to a different printer first, so we never leave a second printer
        // open with us still set as its delegate.
        if let existing, existing !== starPrinter {
            await teardown(existing)
        }

        connectionStatusSubject.send(.connecting)
        do {
            starPrinter.printerDelegate = self
            try await starPrinter.open()
            lock.lock()
            printer = starPrinter
            lock.unlock()
            connectionStatusSubject.send(.connected)
            DDLogInfo("🖨️ Connected to printer \(device.id)")
        } catch {
            connectionStatusSubject.send(.disconnected)
            DDLogError("🖨️ Printer connection failed: \(error.localizedDescription)")
            throw error
        }
    }

    public func disconnect() async {
        lock.lock()
        let current = printer
        printer = nil
        lock.unlock()

        connectionStatusSubject.send(.disconnecting)
        current?.printerDelegate = nil
        await current?.close()
        connectionStatusSubject.send(.disconnected)
    }
}

private extension StarPrinterService {
    enum Constants {
        static let discoveryTimeInMilliseconds = 30000
    }

    /// Closes `existing` and drops it as the active printer, releasing the delegate. Used while switching to a
    /// new printer, so it stays quiet about connection status, which the in-flight `connect(to:)` then drives.
    func teardown(_ existing: StarPrinter) async {
        existing.printerDelegate = nil
        await existing.close()
        lock.lock()
        if printer === existing {
            printer = nil
        }
        lock.unlock()
    }

    func startDiscovery(streaming continuation: AsyncThrowingStream<PrinterDevice, Error>.Continuation) {
        do {
            let manager = try StarDeviceDiscoveryManagerFactory.create(interfaceTypes: [.bluetooth, .bluetoothLE])
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
            manager.delegate = delegate
            manager.discoveryTime = Constants.discoveryTimeInMilliseconds

            let session = DiscoverySession(manager: manager, delegate: delegate, continuation: continuation)
            // Install (superseding any in-flight session) before starting, so the termination handler also
            // tears the session down if `startDiscovery()` throws.
            install(session)
            let sessionID = session.id
            continuation.onTermination = { [weak self] _ in
                self?.endSession(matching: sessionID)
            }

            try manager.startDiscovery()

            // `startDiscovery()` can take a moment, and during it a newer `discover()` (or a cancel) may have
            // superseded this session, already finishing its stream. If so, stop the manager we just started so
            // it does not keep scanning untracked, and finish (a no-op if already finished). Supersession is a
            // normal lifecycle event rather than a failure, so we finish without an error here, unlike a real
            // SDK failure, which finishes with `.discoveryFailure` in the catch below.
            if !isActive(session) {
                manager.stopDiscovery()
                continuation.finish()
            }
        } catch {
            DDLogError("🖨️ Printer discovery failed: \(error.localizedDescription)")
            continuation.finish(throwing: PrinterError.discoveryFailure)
        }
    }

    /// Makes `session` the active one, finishing and stopping any session it replaces.
    func install(_ session: DiscoverySession) {
        lock.lock()
        let previous = activeSession
        activeSession = session
        lock.unlock()

        guard let previous else {
            return
        }
        // `previous` is a local snapshot taken under the lock and all its fields are immutable, so the work
        // below touches no shared mutable state and is deliberately done unlocked. It must be unlocked too:
        // finishing the stream can re-enter via its termination handler (`endSession`), which takes the lock,
        // so holding a non-recursive `NSLock` here would deadlock.
        //
        // Finish the superseded stream explicitly rather than relying on the SDK to deliver a final callback.
        // Keep the delegate alive only while stopping its manager, then release it: StarIO10 holds the delegate
        // weakly, so releasing it under the lock could deallocate it and re-enter via the same handler.
        previous.continuation.finish()
        withExtendedLifetime(previous.delegate) {
            previous.manager.stopDiscovery()
        }
    }

    /// Tears down the session with this id, but only while it is still the active one.
    func endSession(matching id: UUID) {
        lock.lock()
        guard let session = activeSession, session.id == id else {
            lock.unlock()
            return
        }
        activeSession = nil
        lock.unlock()

        session.manager.stopDiscovery()
    }

    func isActive(_ session: DiscoverySession) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return activeSession === session
    }

    func storeDiscoveredPrinter(_ starPrinter: StarPrinter, for device: PrinterDevice) {
        lock.lock()
        discoveredPrinters[device.id] = starPrinter
        lock.unlock()
    }
}

/// Bundles the state for a single `discover()` call, so a session's manager, delegate, and stream
/// continuation stay together and the session can be compared by identity.
private final class DiscoverySession {
    let id = UUID()
    let manager: StarDeviceDiscoveryManager
    // `StarDeviceDiscoveryManager` holds its delegate weakly, so the session owns it strongly to keep it alive
    // for the discovery's lifetime; without this, the delegate would deallocate and discovery callbacks would
    // never fire.
    // swiftlint:disable:next weak_delegate
    let delegate: StarDiscoveryDelegate
    let continuation: AsyncThrowingStream<PrinterDevice, Error>.Continuation

    init(manager: StarDeviceDiscoveryManager,
         delegate: StarDiscoveryDelegate,
         continuation: AsyncThrowingStream<PrinterDevice, Error>.Continuation) {
        self.manager = manager
        self.delegate = delegate
        self.continuation = continuation
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
