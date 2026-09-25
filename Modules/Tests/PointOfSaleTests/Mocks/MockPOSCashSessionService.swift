import Foundation
@testable import PointOfSale

@MainActor
final class MockPOSCashSessionService: POSCashSessionService {
    private(set) var recordedCashSaleOrderIDs: [Int64] = []
    private(set) var recordedCashRefunds: [(orderID: Int64, refundID: Int64)] = []
    private(set) var requestedPastSessionPages: [Int] = []
    var onCashSaleRecorded: ((Int64) -> Void)?
    var onCashRefundRecorded: ((Int64, Int64) -> Void)?
    var onPastSessionsRequested: (@MainActor (Int) -> Void)?
    var pastSessionsToReturn = POSCashSessionPage(sessions: [], hasMore: false)
    var pastSessionsError: Error?
    var hasPendingCashMovements = false
    var isRetryingCashMovements = false
    var capturedSessionID: Int64? = 123
    var captureError: Error?
    var currentSessionToReturn: POSCashSession?
    var currentSessionError: Error?
    var closeError: Error?
    var closeSessionToReturn: POSCashSession?
    var closeCallCount = 0
    private(set) var closeExpectedRevisions: [Int] = []
    var captureCallCount = 0
    var retryCallCount = 0
    var retrySucceeds = true
    private(set) var enqueuedSessionIDs: [Int64] = []

    func captureCashSession() async throws -> Int64? {
        captureCallCount += 1
        if let captureError { throw captureError }
        return capturedSessionID
    }

    func enqueueCashSale(orderID: Int64, sessionID: Int64) throws {
        enqueuedSessionIDs.append(sessionID)
        recordedCashSaleOrderIDs.append(orderID)
        hasPendingCashMovements = true
        onCashSaleRecorded?(orderID)
    }

    func enqueueCashRefund(orderID: Int64, refundID: Int64, sessionID: Int64) throws {
        enqueuedSessionIDs.append(sessionID)
        recordedCashRefunds.append((orderID, refundID))
        hasPendingCashMovements = true
        onCashRefundRecorded?(orderID, refundID)
    }

    func retryPendingCashMovements() async {
        retryCallCount += 1
        if retrySucceeds { hasPendingCashMovements = false }
    }

    func currentSession() async throws -> POSCashSession? {
        if let currentSessionError { throw currentSessionError }
        return currentSessionToReturn
    }

    func pastSessions(page: Int, perPage: Int) async throws -> POSCashSessionPage {
        requestedPastSessionPages.append(page)
        onPastSessionsRequested?(page)
        if let pastSessionsError {
            throw pastSessionsError
        }
        return pastSessionsToReturn
    }

    func session(id: Int64) async throws -> POSCashSession { throw POSCashSessionServiceError.noOpenSession }
    func startSession(openingCash: Decimal) async throws -> POSCashSession { throw POSCashSessionServiceError.noOpenSession }
    func recordMovement(sessionID: Int64, kind: POSCashSessionMovement.Kind, amount: Decimal, note: String?) async throws -> POSCashSession {
        throw POSCashSessionServiceError.noOpenSession
    }
    func closeSession(sessionID: Int64, expectedRevision: Int, countedCash: Decimal, note: String?) async throws -> POSCashSession {
        closeCallCount += 1
        closeExpectedRevisions.append(expectedRevision)
        if let closeError { throw closeError }
        guard let closeSessionToReturn else { throw POSCashSessionServiceError.noOpenSession }
        return closeSessionToReturn
    }

    func recordCashSale(orderID: Int64) async throws -> POSCashSession? {
        recordedCashSaleOrderIDs.append(orderID)
        onCashSaleRecorded?(orderID)
        return nil
    }

    func recordCashRefund(orderID: Int64, refundID: Int64) async throws -> POSCashSession? {
        recordedCashRefunds.append((orderID, refundID))
        onCashRefundRecorded?(orderID, refundID)
        return nil
    }
}
