import Foundation
import Combine
import StarIO10

/// Concrete `PrinterDiscoveryService` backed by the Star Micronics StarIO10 SDK.
///
/// Discovers Star printers over Bluetooth and manages the connection lifecycle. The mapping
/// from a discovered `StarPrinter` to its Hardware-domain `PrinterDevice` is kept here,
/// so callers connect by `PrinterDevice` without ever touching StarIO10 types.
///
/// All SDK interaction and mutable state live on the `StarPrinterCoordinator` actor, which
/// serializes access so callbacks and the discovery/connection methods can never race. This
/// type is a thin façade that adapts the actor to the synchronous parts of the protocol.
public final class StarPrinterService: PrinterDiscoveryService {
    private let connectionStatusSubject = CurrentValueSubject<PrinterConnectionStatus, Never>(.idle)
    private let coordinator: StarPrinterCoordinator

    public init() {
        // Opt out of StarIO10's diagnostic-info upload, which is enabled by default.
        StarIO10DiagInfoUpload.shared.isEnabled = false

        let subject = connectionStatusSubject
        coordinator = StarPrinterCoordinator { status in
            subject.send(status)
        }
    }

    public var connectionStatusPublisher: AnyPublisher<PrinterConnectionStatus, Never> {
        connectionStatusSubject.eraseToAnyPublisher()
    }

    public func discover() -> AsyncThrowingStream<PrinterDevice, Error> {
        AsyncThrowingStream { [coordinator] continuation in
            let task = Task {
                await coordinator.runDiscovery(emitting: continuation)
            }
            // When the consumer drops or cancels the stream, cancel the discovery task; the
            // coordinator then stops the underlying SDK scan as it unwinds.
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    public func stopDiscovery() {
        Task { [coordinator] in
            await coordinator.stopDiscovery()
        }
    }

    public func connect(to device: PrinterDevice) async throws {
        try await coordinator.connect(to: device)
    }

    public func disconnect() async {
        await coordinator.disconnect()
    }
}

/// Owns every StarIO10 object and all mutable connection/discovery state.
///
/// Being an actor, it serializes all access on a single executor, so the discovery callbacks (funnelled
/// in via `StarDiscoveryEvent`) and the `connect`/`disconnect`/`stopDiscovery` calls never interleave on
/// shared state. This is what lets the rest of the file stay lock-free.
private actor StarPrinterCoordinator {
    /// The in-flight discovery, if any. Compared by identity (`===`) so a superseded discovery that is
    /// still unwinding never mistakes itself for the current one once a newer discovery has replaced it.
    private var activeSession: DiscoverySession?

    /// Maps a discovered device's identifier to its underlying `StarPrinter`,
    /// so we can connect by `PrinterDevice` without exposing StarIO10 types.
    private var discoveredPrinters: [String: StarPrinter] = [:]

    private var printer: StarPrinter?

    /// Retained for the connected printer's lifetime so the SDK delegate stays alive; released on disconnect.
    /// `StarPrinter` holds `printerDelegate` weakly, so a strong reference here keeps ours from deallocating.
    // swiftlint:disable:next weak_delegate
    private var connectionDelegate: StarConnectionDelegate?

    /// Whether a `connect(to:)` is in flight, so overlapping calls are rejected and we stay the delegate of at
    /// most one printer at a time. The check-and-set is atomic here because the actor admits no other call
    /// between the guard and the assignment below (there is no suspension point between them).
    private var isConnecting = false

    private let emitStatus: (PrinterConnectionStatus) -> Void

    init(emitStatus: @escaping (PrinterConnectionStatus) -> Void) {
        self.emitStatus = emitStatus
    }

    func runDiscovery(emitting out: AsyncThrowingStream<PrinterDevice, Error>.Continuation) async {
        supersedeActiveSession()

        let session: DiscoverySession
        do {
            let manager = try StarDeviceDiscoveryManagerFactory.create(interfaceTypes: [.bluetooth, .bluetoothLE])
            // The delegate yields each callback into this funnel in the exact order StarIO10 calls it, on its
            // own thread. Draining the funnel below (the single consumer) preserves that order while moving the
            // work onto the actor, so we get Star's synchronous ordering without a lock.
            let (events, eventsContinuation) = AsyncStream.makeStream(of: StarDiscoveryEvent.self)
            let delegate = StarDiscoveryDelegate(continuation: eventsContinuation)
            manager.delegate = delegate
            manager.discoveryTime = Constants.discoveryTimeInMilliseconds

            session = DiscoverySession(manager: manager,
                                       delegate: delegate,
                                       events: eventsContinuation,
                                       out: out)
            activeSession = session

            try manager.startDiscovery()

            for await event in events {
                switch event {
                case .found(let starPrinter):
                    let device = PrinterDevice(id: starPrinter.connectionSettings.identifier,
                                               name: starPrinter.connectionSettings.identifier)
                    discoveredPrinters[device.id] = starPrinter
                    out.yield(device)
                }
            }
        } catch {
            DDLogError("🖨️ Printer discovery failed: \(error.localizedDescription)")
            activeSession = nil
            out.finish(throwing: PrinterError.discoveryFailure)
            return
        }

        // The funnel finished: StarIO10 ended discovery, the consumer cancelled, or a newer discovery
        // superseded this one. Stop the SDK scan and clear the slot only if we are still the active session,
        // so a superseded run leaves the newer one untouched.
        if activeSession === session {
            session.manager.stopDiscovery()
            activeSession = nil
        }
        out.finish()
    }

    func stopDiscovery() {
        activeSession?.manager.stopDiscovery()
    }

    func connect(to device: PrinterDevice) async throws {
        guard !isConnecting else {
            DDLogError("🖨️ A connection is already in progress; ignoring connect for \(device.id)")
            throw PrinterError.connectionInProgress
        }
        guard let starPrinter = discoveredPrinters[device.id] else {
            DDLogError("🖨️ No discovered printer matches device id \(device.id)")
            throw PrinterError.printerNotFound
        }

        isConnecting = true
        defer { isConnecting = false }

        // Tear down any current connection to a different printer first, so we never leave a second printer
        // open with us still set as its delegate.
        if let existing = printer, existing !== starPrinter {
            await teardown(existing)
        }

        emitStatus(.connecting)
        let delegate = StarConnectionDelegate()
        starPrinter.printerDelegate = delegate
        do {
            try await starPrinter.open()
            printer = starPrinter
            connectionDelegate = delegate
            emitStatus(.connected)
            DDLogInfo("🖨️ Connected to printer \(device.id)")
        } catch {
            starPrinter.printerDelegate = nil
            emitStatus(.disconnected)
            DDLogError("🖨️ Printer connection failed: \(error.localizedDescription)")
            throw error
        }
    }

    func disconnect() async {
        let current = printer
        printer = nil
        connectionDelegate = nil

        emitStatus(.disconnecting)
        current?.printerDelegate = nil
        await current?.close()
        emitStatus(.disconnected)
    }
}

private extension StarPrinterCoordinator {
    enum Constants {
        static let discoveryTimeInMilliseconds = 30000
    }

    /// Closes `existing` and drops it as the active printer, releasing its delegate. Used while switching to a
    /// new printer, so it stays quiet about connection status, which the in-flight `connect(to:)` then drives.
    func teardown(_ existing: StarPrinter) async {
        existing.printerDelegate = nil
        await existing.close()
        if printer === existing {
            printer = nil
            connectionDelegate = nil
        }
    }

    /// Ends and stops the in-flight discovery, if any, before a newer one takes its place.
    func supersedeActiveSession() {
        guard let previous = activeSession else {
            return
        }
        activeSession = nil
        // Finish the superseded caller's stream, then end the funnel so its `for await` loop exits, then stop
        // the SDK scan. The loop's own cleanup is a no-op once it sees it is no longer the active session.
        previous.out.finish()
        previous.events.finish()
        previous.manager.stopDiscovery()
    }
}

/// One callback from StarIO10's discovery delegate, funnelled to the coordinator in call order.
///
/// `StarPrinter` is not `Sendable`; this is the single point where one crosses from the SDK's callback
/// thread to the actor, and it is moved straight into actor-isolated state on arrival.
private enum StarDiscoveryEvent {
    case found(StarPrinter)
}

/// Bundles the state for a single `discover()` call, so a session's manager, delegate, event funnel, and
/// output stream stay together and the session can be compared by identity.
private final class DiscoverySession {
    let manager: any StarDeviceDiscoveryManager
    // `StarDeviceDiscoveryManager` holds its delegate weakly, so the session owns it strongly to keep it alive
    // for the discovery's lifetime; without this, the delegate would deallocate and discovery callbacks would
    // never fire.
    // swiftlint:disable:next weak_delegate
    let delegate: StarDiscoveryDelegate
    let events: AsyncStream<StarDiscoveryEvent>.Continuation
    let out: AsyncThrowingStream<PrinterDevice, Error>.Continuation

    init(manager: any StarDeviceDiscoveryManager,
         delegate: StarDiscoveryDelegate,
         events: AsyncStream<StarDiscoveryEvent>.Continuation,
         out: AsyncThrowingStream<PrinterDevice, Error>.Continuation) {
        self.manager = manager
        self.delegate = delegate
        self.events = events
        self.out = out
    }
}

/// Bridges StarIO10 discovery callbacks into the discovery event funnel, preserving their order.
private final class StarDiscoveryDelegate: NSObject, StarDeviceDiscoveryManagerDelegate {
    private let continuation: AsyncStream<StarDiscoveryEvent>.Continuation

    init(continuation: AsyncStream<StarDiscoveryEvent>.Continuation) {
        self.continuation = continuation
    }

    func manager(_ manager: any StarDeviceDiscoveryManager, didFind printer: StarPrinter) {
        DDLogInfo("🖨️ Found printer \(printer.connectionSettings.identifier)")
        continuation.yield(.found(printer))
    }

    func managerDidFinishDiscovery(_ manager: any StarDeviceDiscoveryManager) {
        DDLogInfo("🖨️ Finished printer discovery")
        continuation.finish()
    }
}

/// Receives StarIO10 printer-status callbacks for a connected printer. Stateless: logs only.
private final class StarConnectionDelegate: NSObject, PrinterDelegate {
    func printer(_ printer: StarPrinter, communicationErrorDidOccur error: any Error) {
        DDLogError("🖨️ Printer communication error: \(error.localizedDescription)")
    }

    func printerIsReady(_ printer: StarPrinter) {
        DDLogInfo("🖨️ Printer is ready")
    }

    func printerDidHaveError(_ printer: StarPrinter) {
        DDLogError("🖨️ Printer reported an error")
    }

    func printerIsPaperReady(_ printer: StarPrinter) {
        DDLogInfo("🖨️ Printer paper is ready")
    }

    func printerIsPaperNearEmpty(_ printer: StarPrinter) {
        DDLogInfo("🖨️ Printer paper is near empty")
    }

    func printerIsPaperEmpty(_ printer: StarPrinter) {
        DDLogInfo("🖨️ Printer paper is empty")
    }

    func printerIsCoverOpen(_ printer: StarPrinter) {
        DDLogInfo("🖨️ Printer cover is open")
    }

    func printerIsCoverClose(_ printer: StarPrinter) {
        DDLogInfo("🖨️ Printer cover is closed")
    }
}
