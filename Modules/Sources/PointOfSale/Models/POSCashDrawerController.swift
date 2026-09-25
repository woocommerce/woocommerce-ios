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
}

/// The outcome of asking the drawer to open.
enum POSCashDrawerOpenResult: Equatable {
    case opened
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
}

/// Opens the cash drawer connected to the receipt printer.
///
/// The drawer is a device capability, separate from cash accounting: this controller never
/// changes session totals. Opening never throws, so a missing or failing drawer can't block a sale.
@MainActor
@Observable
final class POSCashDrawerController {
    /// Whether the drawer opens by itself when a cash sale or cash refund is confirmed.
    var opensAutomaticallyForCashPayments: Bool {
        didSet {
            userDefaults.set(opensAutomaticallyForCashPayments, forKey: Constants.opensAutomaticallyKey)
        }
    }

    /// The most recent open attempt, so the UI can show a clear notice when the drawer is unavailable.
    private(set) var lastEvent: POSCashDrawerEvent?

    /// Called after every open attempt. The session layer can use this to log no-sale opens.
    @ObservationIgnored var onDrawerEvent: ((POSCashDrawerEvent) -> Void)?

    @ObservationIgnored private let service: CashDrawerService
    @ObservationIgnored private let userDefaults: UserDefaults
    @ObservationIgnored private let now: () -> Date

    init(service: CashDrawerService,
         userDefaults: UserDefaults = .standard,
         now: @escaping () -> Date = Date.init) {
        self.service = service
        self.userDefaults = userDefaults
        self.now = now
        self.opensAutomaticallyForCashPayments = userDefaults.object(forKey: Constants.opensAutomaticallyKey) as? Bool ?? true
    }

    /// Opens the drawer after a confirmed cash sale or cash refund, if automatic opening is on.
    func openAutomatically(for reason: POSCashDrawerOpenReason) async {
        guard opensAutomaticallyForCashPayments else {
            return
        }
        await open(for: reason)
    }

    /// Opens the drawer and reports the outcome. Never throws.
    @discardableResult
    func open(for reason: POSCashDrawerOpenReason) async -> POSCashDrawerOpenResult {
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

        let event = POSCashDrawerEvent(reason: reason, result: result, date: now())
        lastEvent = event
        onDrawerEvent?(event)
        return result
    }
}

private extension POSCashDrawerController {
    enum Constants {
        static let opensAutomaticallyKey = "pos-cash-drawer-opens-automatically"
    }
}
