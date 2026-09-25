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

    func currentSession() async throws -> POSCashSession? { nil }

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
        throw POSCashSessionServiceError.noOpenSession
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
