import Combine
import Foundation
import Yosemite
import PointOfSale
import UIKit

/// Maps the Core cash-session API to the POS presentation model.
@MainActor
final class POSCashSessionAdaptor: POSCashSessionService {
    private let remote: POSCashSessionRemoteService
    private let siteID: Int64
    private let deviceID: String
    private var pendingRequestIDs: [String: UUID] = [:]
    private lazy var cashEventRecorder = POSCashEventRecorder.shared(siteID: siteID, deviceID: deviceID) { [weak self] event in
        guard let self else { throw URLError(.cannotConnectToHost) }
        try await self.recordCashEvent(event)
    }

    var hasPendingCashMovements: Bool { cashEventRecorder.hasPendingEvents }
    var isRetryingCashMovements: Bool { cashEventRecorder.isRetrying }

    init(remote: POSCashSessionRemoteService, siteID: Int64, deviceID: String) {
        self.remote = remote
        self.siteID = siteID
        self.deviceID = deviceID
    }

    convenience init?(credentials: Credentials?,
                      selectedSite: AnyPublisher<POSCashSessionSite?, Never>,
                      appPasswordSupportState: AnyPublisher<Bool, Never>,
                      siteID: Int64) {
        guard let remote = POSCashSessionRemoteService(credentials: credentials,
                                                       selectedSite: selectedSite,
                                                       appPasswordSupportState: appPasswordSupportState) else { return nil }
        self.init(remote: remote,
                  siteID: siteID,
                  deviceID: Self.stableDeviceID())
    }

    func captureCashSession() async throws -> Int64? {
        let sessionID: Int64?
        do {
            sessionID = try await mappingUnsupportedEndpoint { try await activeSessionID() }
        } catch POSCashSessionServiceError.unsupported {
            return nil
        }
        if sessionID != nil { try cashEventRecorder.prepare() }
        return sessionID
    }

    func enqueueCashSale(orderID: Int64, sessionID: Int64) throws {
        guard orderID > 0 else { throw POSCashSessionServiceError.invalidReference }
        try cashEventRecorder.enqueue(siteID: siteID, sessionID: sessionID, source: .sale(orderID: orderID))
    }

    func enqueueCashRefund(orderID: Int64, refundID: Int64, sessionID: Int64) throws {
        guard orderID > 0, refundID > 0 else { throw POSCashSessionServiceError.invalidReference }
        try cashEventRecorder.enqueue(siteID: siteID, sessionID: sessionID, source: .refund(orderID: orderID, refundID: refundID))
    }

    func retryPendingCashMovements() async {
        await cashEventRecorder.retry()
    }

    func currentSession() async throws -> POSCashSession? {
        let sessions = try await mappingUnsupportedEndpoint {
            try await remote.listSessions(siteID: siteID, deviceID: deviceID, status: "open", page: 1, perPage: 1)
        }
        guard let response = sessions.items.first else { return nil }
        return try await mappedSession(response, withMovements: true)
    }

    func pastSessions(page: Int, perPage: Int) async throws -> POSCashSessionPage {
        let responses = try await mappingUnsupportedEndpoint {
            try await remote.listSessions(siteID: siteID, deviceID: nil, status: "closed", page: page, perPage: perPage)
        }
        return try POSCashSessionPage(sessions: responses.items.map { try mapSession($0, movements: []) },
                                      hasMore: responses.hasMorePages && responses.items.count == perPage)
    }

    func session(id: Int64) async throws -> POSCashSession {
        let response = try await remote.session(siteID: siteID, id: id)
        return try await mappedSession(response, withMovements: true)
    }

    func startSession(openingCash: Decimal) async throws -> POSCashSession {
        guard openingCash >= 0 else { throw POSCashSessionServiceError.invalidAmount }
        let requestKey = "open:\(decimalString(openingCash))"
        do {
            let response = try await remote.openSession(siteID: siteID, requestID: requestID(for: requestKey),
                                                        deviceID: deviceID, openingAmount: decimalString(openingCash))
            // An idempotent replay can return a session that another client has since closed.
            guard response.status == "open" else { throw POSCashSessionServiceError.sessionChanged }
            let session = try await mappedSession(response, withMovements: true)
            pendingRequestIDs.removeValue(forKey: requestKey)
            return session
        } catch let error as POSCashSessionAPIError where error.statusCode == 409 {
            throw POSCashSessionServiceError.sessionAlreadyOpen
        }
    }

    func recordMovement(sessionID: Int64, kind: POSCashSessionMovement.Kind, amount: Decimal,
                        note: String?) async throws -> POSCashSession {
        guard amount > 0, let type = Self.movementType(for: kind) else {
            throw POSCashSessionServiceError.invalidAmount
        }
        // Core requires a reason for paid in/out. The UI description remains optional.
        let reason = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedReason = reason.flatMap { $0.isEmpty ? nil : $0 } ?? Self.defaultMovementReason
        let requestKey = "movement:\(sessionID):\(type):\(decimalString(amount)):\(resolvedReason)"
        do {
            _ = try await remote.recordMovement(siteID: siteID, sessionID: sessionID,
                                                requestID: requestID(for: requestKey), type: type,
                                                amount: decimalString(amount), reason: resolvedReason)
            let session = try await self.session(id: sessionID)
            pendingRequestIDs.removeValue(forKey: requestKey)
            return session
        } catch let error as POSCashSessionAPIError where error.statusCode == 404 {
            throw POSCashSessionServiceError.noOpenSession
        }
    }

    func recordCashSale(orderID: Int64) async throws -> POSCashSession? {
        guard let activeID = try await activeSessionID() else { return nil }
        let requestKey = "cashSale:\(activeID):\(orderID)"
        do {
            _ = try await remote.recordCashSale(siteID: siteID, sessionID: activeID,
                                                requestID: requestID(for: requestKey), orderID: orderID)
        } catch let error as POSCashSessionAPIError where sourceAlreadyRecorded(error, in: activeID) {
            // A previous attempt with another request ID has already added this order.
        } catch {
            throw error
        }
        let response = try await remote.session(siteID: siteID, id: activeID)
        let updated = try mapSession(response, movements: [])
        pendingRequestIDs.removeValue(forKey: requestKey)
        return updated
    }

    func recordCashRefund(orderID: Int64, refundID: Int64) async throws -> POSCashSession? {
        guard let activeID = try await activeSessionID() else { return nil }
        let requestKey = "cashRefund:\(activeID):\(orderID):\(refundID)"
        do {
            _ = try await remote.recordCashRefund(siteID: siteID, sessionID: activeID,
                                                  requestID: requestID(for: requestKey),
                                                  orderID: orderID, refundID: refundID)
        } catch let error as POSCashSessionAPIError where sourceAlreadyRecorded(error, in: activeID) {
            // A previous attempt with another request ID has already added this refund.
        } catch {
            throw error
        }
        let response = try await remote.session(siteID: siteID, id: activeID)
        let updated = try mapSession(response, movements: [])
        pendingRequestIDs.removeValue(forKey: requestKey)
        return updated
    }

    func closeSession(sessionID: Int64, expectedRevision: Int, countedCash: Decimal,
                      note: String?) async throws -> POSCashSession {
        guard !hasPendingCashMovements else { throw POSCashSessionServiceError.pendingCashMovements }
        guard countedCash >= 0 else { throw POSCashSessionServiceError.invalidAmount }
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let requestKey = "close:\(sessionID):\(expectedRevision):\(decimalString(countedCash)):\(trimmedNote ?? "")"
        do {
            let response = try await remote.closeSession(siteID: siteID, sessionID: sessionID,
                                                         requestID: requestID(for: requestKey),
                                                         expectedRevision: expectedRevision,
                                                         countedAmount: decimalString(countedCash),
                                                         note: trimmedNote.flatMap { $0.isEmpty ? nil : $0 })
            let session = try await mappedSession(response, withMovements: true)
            pendingRequestIDs.removeValue(forKey: requestKey)
            return session
        } catch let error as POSCashSessionAPIError where error.statusCode == 409 &&
            error.code == "woocommerce_rest_cash_session_revision_conflict" {
            throw POSCashSessionServiceError.sessionChanged
        }
    }
}

private extension POSCashSessionAdaptor {
    func recordCashEvent(_ event: POSCashEvent) async throws {
        switch event.source {
        case .sale(let orderID):
            _ = try await remote.recordCashSale(siteID: event.siteID, sessionID: event.sessionID,
                                                requestID: event.requestID, orderID: orderID)
        case .refund(let orderID, let refundID):
            _ = try await remote.recordCashRefund(siteID: event.siteID, sessionID: event.sessionID,
                                                  requestID: event.requestID, orderID: orderID, refundID: refundID)
        }
    }

    /// A store whose WooCommerce version has no `wc/pos/v1/cash-sessions` route answers 404 `rest_no_route`,
    /// as `DotcomError.noRestRoute` through the Jetpack tunnel or `NetworkError.notFound` over direct REST.
    func mappingUnsupportedEndpoint<T>(_ operation: () async throws -> T) async throws -> T {
        do {
            return try await operation()
        } catch let error as POSCashSessionAPIError {
            if error.statusCode == 404, error.code == "rest_no_route" {
                throw POSCashSessionServiceError.unsupported
            }
            throw error
        }
    }

    func activeSessionID() async throws -> Int64? {
        let sessions = try await remote.listSessions(siteID: siteID, deviceID: deviceID, status: "open", page: 1, perPage: 1)
        return sessions.items.first?.id
    }

    static let defaultMovementReason = NSLocalizedString("pos.cashSession.movement.defaultReason",
                                                          value: "Cash adjustment",
                                                          comment: "Reason sent to the server when no paid in or paid out description is entered")

    static func stableDeviceID() -> String {
        if let vendorID = UIDevice.current.identifierForVendor?.uuidString { return vendorID }
        let key = "pos.cashSession.deviceID"
        if let stored = UserDefaults.standard.string(forKey: key) { return stored }
        let generated = UUID().uuidString
        UserDefaults.standard.set(generated, forKey: key)
        return generated
    }

    static func movementType(for kind: POSCashSessionMovement.Kind) -> String? {
        switch kind {
        case .payIn: "paid_in"
        case .payOut: "paid_out"
        case .cashSale, .cashRefund: nil // Source-backed movements need an order/refund reference.
        }
    }

    func requestID(for key: String) -> UUID {
        if let existing = pendingRequestIDs[key] { return existing }
        let new = UUID()
        pendingRequestIDs[key] = new
        return new
    }

    func sourceAlreadyRecorded(_ error: POSCashSessionAPIError, in sessionID: Int64) -> Bool {
        error.code == "woocommerce_rest_cash_source_already_recorded" && error.recordedSessionID == sessionID
    }

    func decimalString(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }

    func mappedSession(_ response: POSCashSessionResponse, withMovements: Bool) async throws -> POSCashSession {
        let movements = withMovements ? try await loadMovements(sessionID: response.id) : []
        return try mapSession(response, movements: movements)
    }

    func loadMovements(sessionID: Int64) async throws -> [POSCashSessionMovement] {
        let perPage = 100
        var page = 1
        var result: [POSCashSessionMovement] = []
        while true {
            let batch = try await remote.movements(siteID: siteID, sessionID: sessionID, page: page, perPage: perPage)
            result += try batch.items.compactMap(mapMovement)
            if !batch.hasMorePages || batch.items.count < perPage { return result }
            page += 1
        }
    }

    func mapSession(_ response: POSCashSessionResponse, movements: [POSCashSessionMovement]) throws -> POSCashSession {
        let totals = POSCashSessionTotals(cashSales: try decimal(response.cashSalesTotal),
                                          cashRefunds: try decimal(response.cashRefundsTotal),
                                          paidIn: try decimal(response.paidInTotal),
                                          paidOut: try decimal(response.paidOutTotal),
                                          expectedCash: try decimal(response.expectedAmount))
        return try POSCashSession(id: response.id,
                                  openedAt: date(response.dateCreatedGMT),
                                  openedBy: response.openedByName,
                                  openingCash: decimal(response.openingAmount),
                                  movements: movements,
                                  closedAt: response.dateClosedGMT.map(date),
                                  closedBy: response.closedByName,
                                  countedCash: response.countedAmount.map(decimal),
                                  closingNote: response.note,
                                  revision: response.revision,
                                  totals: totals,
                                  currency: response.currency,
                                  currencyPrecision: response.currencyPrecision,
                                  drawerID: response.drawerID)
    }

    func mapMovement(_ response: POSCashMovementResponse) throws -> POSCashSessionMovement? {
        let kind: POSCashSessionMovement.Kind
        switch response.type {
        case "cash_sale": kind = .cashSale
        case "cash_refund": kind = .cashRefund
        case "paid_in": kind = .payIn
        case "paid_out": kind = .payOut
        case "opening_float": return nil // Opening cash is shown in the drawer summary.
        default: throw POSCashSessionMappingError.invalidMovementType(response.type)
        }
        let identifier = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012llX", response.id)) ?? UUID()
        return try POSCashSessionMovement(id: identifier, kind: kind,
                                          amount: decimal(response.amount), date: date(response.occurredAt),
                                          actor: response.createdByName, orderID: response.orderID,
                                          note: response.reason)
    }

    func decimal(_ string: String) throws -> Decimal {
        guard let value = Decimal(string: string, locale: Locale(identifier: "en_US_POSIX")) else {
            throw POSCashSessionMappingError.invalidMoney(string)
        }
        return value
    }

    func date(_ string: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let value = formatter.date(from: string) { return value }
        formatter.formatOptions = [.withInternetDateTime]
        guard let value = formatter.date(from: string) else {
            throw POSCashSessionMappingError.invalidDate(string)
        }
        return value
    }
}

private enum POSCashSessionMappingError: Error {
    case invalidMoney(String)
    case invalidDate(String)
    case invalidMovementType(String)
}
