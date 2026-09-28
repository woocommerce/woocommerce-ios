import CocoaLumberjackSwift
import Foundation
import Observation
import protocol Yosemite.CashDrawerService
import enum Yosemite.PrinterError

/// Why the cash drawer was opened, so each open can be logged against the cash session.
enum POSCashDrawerOpenReason: Equatable {
    /// A cash payment was confirmed.
    case cashSale
    /// A cash refund is being handed back.
    case cashRefund
    /// Opened without a sale, to make change or fix a mistake.
    case noSale
    /// Opened from settings to check the drawer works.
    case test
    /// The drawer's sensor reported an opening the app didn't request, for example with the key.
    case unknown
}

/// The outcome of asking the drawer to open.
enum POSCashDrawerOpenResult: Equatable {
    case opened
    /// An open was requested outside a cash session.
    case noSession
    /// No printer is connected, so the drawer cannot be reached.
    case notConnected
    /// The printer was connected but the open command failed.
    case failed
}

/// One attempt to open the drawer. Session foundation can record these through `onDrawerEvent`.
struct POSCashDrawerEvent: Equatable {
    let reason: POSCashDrawerOpenReason
    let result: POSCashDrawerOpenResult
    let date: Date
    /// The order the drawer opened for, for cash sales and refunds.
    let orderID: Int64?

    init(reason: POSCashDrawerOpenReason, result: POSCashDrawerOpenResult, date: Date, orderID: Int64? = nil) {
        self.reason = reason
        self.result = result
        self.date = date
        self.orderID = orderID
    }
}

/// The session and drawer binding known by the cash management controller at an open attempt.
struct POSCashDrawerSessionSnapshot: Equatable {
    let id: Int64
    let drawerID: String?
}

/// Opens the cash drawer connected to the receipt printer.
///
/// The drawer is a device capability, separate from cash accounting: this controller never
/// changes session totals. Opening never throws, so a missing or failing drawer can't block a sale.
@MainActor
@Observable
final class POSCashDrawerController {
    /// Whether the drawer opens by itself after a cash sale, refund, pay-in, or pay-out is recorded.
    var opensAutomaticallyForCashPayments: Bool {
        didSet {
            userDefaults.set(opensAutomaticallyForCashPayments, forKey: Constants.opensAutomaticallyKey)
        }
    }

    /// The merchant's name for this drawer, such as "Front till". Core uses it as the session's `drawer_id`.
    /// Nil until the merchant names the drawer.
    private(set) var drawerName: String?

    /// Which sensor value means "open" for this drawer. It depends on the drawer, so it is learned from the first
    /// signal change right after an open the app requested. Nil until learned, or for drawers without a sensor.
    private(set) var openSignal: Bool?

    /// The most recent open attempt, so the UI can show a clear notice when the drawer is unavailable.
    private(set) var lastEvent: POSCashDrawerEvent?

    /// Called after every open attempt. The session layer can use this to log no-sale opens.
    @ObservationIgnored var onDrawerEvent: ((POSCashDrawerEvent) -> Void)?

    @ObservationIgnored private let service: CashDrawerService
    /// Records each open attempt in the open cash session. Nil when cash sessions aren't available.
    @ObservationIgnored private let sessionService: (any POSCashSessionService)?
    @ObservationIgnored var sessionSnapshot: (@MainActor () -> POSCashDrawerSessionSnapshot?)?
    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let now: () -> Date
    /// The latest open the app requested, so a sensor open shortly after is linked to it rather than treated as manual.
    @ObservationIgnored private var lastRequestedOpen: RequestedOpen?
    /// The last sensor value, so only a change to "open" counts as an opening.
    @ObservationIgnored private var lastSignal: Bool?

    init(service: CashDrawerService,
         sessionService: (any POSCashSessionService)? = nil,
         userDefaults: UserDefaults = .standard,
         now: @escaping () -> Date = Date.init) {
        self.service = service
        self.sessionService = sessionService
        self.userDefaults = userDefaults
        self.now = now
        self.opensAutomaticallyForCashPayments = userDefaults.object(forKey: Constants.opensAutomaticallyKey) as? Bool ?? true
        self.drawerName = userDefaults.string(forKey: Constants.drawerNameKey)
        self.openSignal = userDefaults.object(forKey: Constants.openSignalKey) as? Bool
        observeDrawerSignal()
    }

    /// Saves the drawer name without surrounding whitespace. A blank name clears it, as Core rejects blank drawer names.
    func updateDrawerName(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        drawerName = trimmedName.isEmpty ? nil : trimmedName
        userDefaults.set(drawerName, forKey: Constants.drawerNameKey)
    }

    /// Opens the drawer after a confirmed cash transaction or movement, if automatic opening is on.
    func openAutomatically(for reason: POSCashDrawerOpenReason, orderID: Int64? = nil, sessionID: Int64? = nil) async {
        guard opensAutomaticallyForCashPayments, let sessionID else {
            return
        }
        await performOpen(for: reason, orderID: orderID, sessionID: sessionID, captureCurrentSession: false)
    }

    /// Opens the drawer so the cashier can count the float before starting a session.
    /// This explicit action has no session to record a drawer event against.
    @discardableResult
    func openBeforeSession() async -> POSCashDrawerOpenResult {
        await performOpen(for: .noSale, orderID: nil, sessionID: nil, captureCurrentSession: false)
    }

    /// Opens the drawer and reports the outcome. Never throws.
    @discardableResult
    func open(for reason: POSCashDrawerOpenReason, orderID: Int64? = nil) async -> POSCashDrawerOpenResult {
        await performOpen(for: reason, orderID: orderID, sessionID: nil, captureCurrentSession: true)
    }

    private func performOpen(for reason: POSCashDrawerOpenReason, orderID: Int64?, sessionID: Int64?,
                             captureCurrentSession: Bool) async -> POSCashDrawerOpenResult {
        // The session snapshot is local and captured before hardware starts. The editable drawer
        // name can change during a session; only the session's bound drawer decides event logging.
        let eventSessionID: Int64?
        if captureCurrentSession {
            let session: POSCashDrawerSessionSnapshot?
            if let snapshot = sessionSnapshot?() {
                session = snapshot
            } else if let current = try? await sessionService?.currentSession() {
                // Cash Management may not have loaded yet. Read the binding before opening
                // so a later session cannot receive this drawer event.
                session = POSCashDrawerSessionSnapshot(id: current.id, drawerID: current.drawerID)
            } else {
                session = nil
            }
            if let session {
                eventSessionID = session.drawerID != nil ? session.id : nil
            } else if reason == .test {
                // Hardware tests can run before a session starts, with no event to record in Core.
                eventSessionID = nil
            } else {
                return .noSession
            }
        } else {
            // Payment and refund flows captured this ID from Core before the transaction.
            eventSessionID = sessionID
        }
        let attemptDate = now()
        let result: POSCashDrawerOpenResult
        do {
            try await service.openCashDrawer()
            result = .opened
        } catch PrinterError.printerNotConnected {
            result = .notConnected
        } catch {
            DDLogError("💵 [CashDrawer] Failed to open drawer for \(reason): \(error)")
            result = .failed
        }

        let event = POSCashDrawerEvent(reason: reason, result: result, date: attemptDate, orderID: orderID)
        let correlationID = UUID()
        if result == .opened {
            lastRequestedOpen = RequestedOpen(event: event, correlationID: correlationID, sessionID: eventSessionID)
        }
        lastEvent = event
        onDrawerEvent?(event)
        recordInSession(outcome: result == .opened ? .openRequested : .openFailed, event: event,
                        correlationID: correlationID, sessionID: eventSessionID)
        return result
    }

    /// Handles a change of the drawer's sensor signal. Records an `opened` event when the drawer opens: in the
    /// session of the app's request when it follows one, or as an unknown open (for example with the key) otherwise.
    func handleDrawerSignal(_ signal: Bool) {
        let previousSignal = lastSignal
        lastSignal = signal
        guard signal != previousSignal else {
            return
        }

        let requestedOpen = lastRequestedOpen.flatMap { now().timeIntervalSince($0.event.date) <= Constants.sensorConfirmationWindow ? $0 : nil }
        if openSignal == nil {
            // Learn which value means open from the first change right after an open the app requested.
            guard requestedOpen != nil else {
                return
            }
            openSignal = signal
            userDefaults.set(signal, forKey: Constants.openSignalKey)
        }
        guard signal == openSignal else {
            return
        }

        if let requestedOpen {
            lastRequestedOpen = nil
            recordInSession(outcome: .opened, event: requestedOpen.event, correlationID: requestedOpen.correlationID,
                            sessionID: requestedOpen.sessionID, occurredAt: now())
        } else {
            // Only the local session snapshot is used, so an opening is never recorded in a session it didn't happen in.
            let session = sessionSnapshot?()
            recordInSession(outcome: .opened, event: POSCashDrawerEvent(reason: .unknown, result: .opened, date: now()),
                            correlationID: nil, sessionID: session?.drawerID != nil ? session?.id : nil)
        }
    }
}

private extension POSCashDrawerController {
    struct RequestedOpen {
        let event: POSCashDrawerEvent
        let correlationID: UUID
        let sessionID: Int64?
    }

    func observeDrawerSignal() {
        let signals = service.drawerSignalUpdates()
        Task { [weak self] in
            for await signal in signals {
                guard let self else {
                    return
                }
                self.handleDrawerSignal(signal)
            }
        }
    }

    /// Records the event in the open cash session without waiting, so it never holds up a sale.
    /// Core only accepts drawer events for a session opened with a drawer.
    func recordInSession(outcome: POSCashDrawerEventRecord.Outcome,
                         event: POSCashDrawerEvent,
                         correlationID: UUID?,
                         sessionID: Int64?,
                         occurredAt: Date? = nil) {
        guard let sessionService, let sessionID else {
            return
        }
        let record = POSCashDrawerEventRecord(outcome: outcome,
                                              reason: Self.recordReason(for: event.reason),
                                              orderID: event.orderID,
                                              occurredAt: occurredAt ?? event.date,
                                              correlationID: correlationID)
        Task {
            do {
                try await sessionService.recordDrawerEvent(record, sessionID: sessionID)
                DDLogInfo("💵 [CashDrawer] Recorded drawer event \(record)")
            } catch {
                DDLogError("💵 [CashDrawer] Failed to record drawer event \(record): \(error)")
            }
        }
    }

    static func recordReason(for reason: POSCashDrawerOpenReason) -> POSCashDrawerEventRecord.Reason {
        switch reason {
        case .cashSale:
            return .cashSale
        case .cashRefund:
            return .cashRefund
        case .noSale:
            return .noSale
        case .test:
            return .test
        case .unknown:
            return .unknown
        }
    }
}

private extension POSCashDrawerController {
    enum Constants {
        static let opensAutomaticallyKey = "pos-cash-drawer-opens-automatically"
        static let drawerNameKey = "pos-cash-drawer-name"
        static let openSignalKey = "pos-cash-drawer-open-signal"
        /// How long after an app open a sensor change still counts as that open, rather than a manual one.
        static let sensorConfirmationWindow: TimeInterval = 5
    }
}
