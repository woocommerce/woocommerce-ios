import Foundation
import class Yosemite.POSCashSessionRemoteService
import struct Yosemite.POSCashSessionAPIError
import Testing
import enum Networking.NetworkError
import enum NetworkingCore.DotcomError
import struct NetworkingCore.PagedItems
import struct Networking.POSCashSessionResponse
import struct Networking.POSCashMovementResponse
import struct Networking.POSCashDrawerEventResponse
import protocol Networking.POSCashSessionRemoteProtocol
import enum PointOfSale.POSCashSessionServiceError
import struct PointOfSale.POSCashDrawerEventRecord
@testable import WooCommerce

@MainActor
struct POSCashSessionAdaptorTests {
    private let siteID: Int64 = 123

    @Test func test_currentSession_when_dotcom_noRestRoute_then_throws_unsupported() async {
        // Given
        let sut = makeSUT(listError: DotcomError.noRestRoute())

        // Then
        await #expect(throws: POSCashSessionServiceError.unsupported) {
            // When
            _ = try await sut.currentSession()
        }
    }

    @Test func test_currentSession_when_network_notFound_rest_no_route_then_throws_unsupported() async {
        // Given
        let sut = makeSUT(listError: networkError(statusCode: 404, code: "rest_no_route"))

        // Then
        await #expect(throws: POSCashSessionServiceError.unsupported) {
            // When
            _ = try await sut.currentSession()
        }
    }

    @Test func test_pastSessions_when_network_notFound_rest_no_route_then_throws_unsupported() async {
        // Given
        let sut = makeSUT(listError: networkError(statusCode: 404, code: "rest_no_route"))

        // Then
        await #expect(throws: POSCashSessionServiceError.unsupported) {
            // When
            _ = try await sut.pastSessions(page: 1, perPage: 20)
        }
    }

    @Test func test_currentSession_when_network_notFound_without_rest_no_route_then_throws_api_error() async {
        // Given
        let sut = makeSUT(listError: networkError(statusCode: 404, code: "woocommerce_rest_cash_session_not_found"))

        // Then
        await #expect(throws: POSCashSessionAPIError.self) {
            // When
            _ = try await sut.currentSession()
        }
    }

    @Test func test_currentSession_when_server_error_then_throws_api_error() async {
        // Given
        let sut = makeSUT(listError: networkError(statusCode: 500))

        // Then
        await #expect(throws: POSCashSessionAPIError.self) {
            // When
            _ = try await sut.currentSession()
        }
    }

    @Test func test_close_when_revision_conflicts_then_asks_for_review() async {
        // Given
        let sut = makeSUT(listError: UnexpectedCallError(),
                          closeError: networkError(statusCode: 409, code: "woocommerce_rest_cash_session_revision_conflict"))

        // Then
        await #expect(throws: POSCashSessionServiceError.sessionChanged) {
            // When
            _ = try await sut.closeSession(sessionID: 1, expectedRevision: 1, countedCash: 10, note: nil)
        }
    }

    @Test func test_close_when_other_conflict_then_preserves_api_error() async {
        // Given
        let sut = makeSUT(listError: UnexpectedCallError(), closeError: networkError(statusCode: 409, code: "other_conflict"))

        // Then
        await #expect(throws: POSCashSessionAPIError.self) {
            // When
            _ = try await sut.closeSession(sessionID: 1, expectedRevision: 1, countedCash: 10, note: nil)
        }
    }

    @Test func test_session_when_api_returns_drawer_name_then_preserves_it() async throws {
        // Given
        let response = try JSONDecoder().decode(POSCashSessionResponse.self, from: Data("""
        {
          "id": 42, "device_id": "pos-1", "drawer_id": "Front counter", "status": "closed", "revision": 2,
          "currency": "USD", "currency_precision": 2, "opening_amount": "100.00",
          "cash_sales_total": "20.00", "cash_refunds_total": "0.00", "paid_in_total": "0.00",
          "paid_out_total": "0.00", "expected_amount": "120.00", "counted_amount": "120.00",
          "variance": "0.00", "note": null, "date_created_gmt": "2026-09-25T10:00:00Z",
          "date_closed_gmt": "2026-09-25T11:00:00Z", "opened_by_name": "Thomas", "closed_by_name": "Maria"
        }
        """.utf8))
        let sut = makeSUT(sessionResponse: response)

        // When
        let session = try await sut.session(id: response.id)

        // Then
        #expect(session.drawerID == "Front counter")
    }

    @Test func test_recordMovement_when_saved_but_session_refresh_fails_then_reports_saved_adjustment() async throws {
        // Given
        let movement = try JSONDecoder().decode(POSCashMovementResponse.self, from: Data("""
        {"id": 7, "type": "paid_in", "amount": "10.00", "reason": "Cash adjustment", "order_id": null,
         "occurred_at": "2026-09-25T10:00:00Z", "created_by_name": "Thomas"}
        """.utf8))
        let remote = MockPOSCashSessionRemote(listError: UnexpectedCallError(), sessionError: UnexpectedCallError(),
                                              movementResponse: movement)
        let sut = POSCashSessionAdaptor(remote: POSCashSessionRemoteService(remote: remote),
                                        siteID: siteID, deviceID: UUID().uuidString)
        let requestID = UUID()

        // Then
        await #expect(throws: POSCashSessionServiceError.movementRecordedRefreshFailed) {
            // When
            _ = try await sut.recordMovement(sessionID: 1, kind: .payIn, amount: 10, note: nil, requestID: requestID)
        }
        #expect(remote.recordedMovementRequestIDs == [requestID])
    }

    @Test func test_recordDrawerEvent_when_session_was_captured_then_posts_to_that_session() async throws {
        // Given
        let response = try JSONDecoder().decode(POSCashDrawerEventResponse.self,
                                                from: Data("{\"id\":7,\"type\":\"open_requested\",\"reason\":\"no_sale\"}".utf8))
        let remote = MockPOSCashSessionRemote(listError: UnexpectedCallError(), drawerEventResponse: response)
        let sut = POSCashSessionAdaptor(remote: POSCashSessionRemoteService(remote: remote),
                                        siteID: siteID, deviceID: UUID().uuidString)
        let event = POSCashDrawerEventRecord(outcome: .openRequested, reason: .noSale,
                                             orderID: nil, occurredAt: Date(timeIntervalSince1970: 1_000))

        // When
        try await sut.recordDrawerEvent(event, sessionID: 42)

        // Then
        #expect(remote.recordedDrawerEventSessionIDs == [42])
    }

    @Test func test_session_when_cash_refund_has_refund_id_then_preserves_order_and_refund_references() async throws {
        // Given
        let sessionResponse = try JSONDecoder().decode(POSCashSessionResponse.self, from: Data("""
        {
          "id": 42, "device_id": "pos-1", "drawer_id": "Front counter", "status": "open", "revision": 2,
          "currency": "USD", "currency_precision": 2, "opening_amount": "100.00",
          "cash_sales_total": "0.00", "cash_refunds_total": "15.00", "paid_in_total": "0.00",
          "paid_out_total": "0.00", "expected_amount": "85.00", "counted_amount": null,
          "variance": null, "note": null, "date_created_gmt": "2026-09-25T10:00:00Z",
          "date_closed_gmt": null, "opened_by_name": "Thomas", "closed_by_name": null
        }
        """.utf8))
        let refund = try JSONDecoder().decode(POSCashMovementResponse.self, from: Data("""
        {"id": 7, "type": "cash_refund", "amount": "15.00", "reason": null,
         "order_id": 55, "refund_id": 66, "occurred_at": "2026-09-25T10:05:00Z", "created_by_name": "Thomas"}
        """.utf8))
        let remote = MockPOSCashSessionRemote(listError: UnexpectedCallError(), sessionResponse: sessionResponse,
                                              movementResponses: [refund])
        let sut = POSCashSessionAdaptor(remote: POSCashSessionRemoteService(remote: remote),
                                        siteID: siteID, deviceID: UUID().uuidString)

        // When
        let session = try await sut.session(id: 42)

        // Then
        #expect(session.movements.count == 1)
        #expect(session.movements[0].orderID == 55)
        #expect(session.movements[0].refundID == 66)
        #expect(session.expectedCash == 85)
    }
}

private extension POSCashSessionAdaptorTests {
    func makeSUT(listError: Error, closeError: Error? = nil) -> POSCashSessionAdaptor {
        POSCashSessionAdaptor(remote: POSCashSessionRemoteService(remote: MockPOSCashSessionRemote(listError: listError,
                                                                                                    closeError: closeError)),
                              siteID: siteID, deviceID: UUID().uuidString)
    }

    func makeSUT(sessionResponse: POSCashSessionResponse) -> POSCashSessionAdaptor {
        POSCashSessionAdaptor(remote: POSCashSessionRemoteService(remote: MockPOSCashSessionRemote(listError: UnexpectedCallError(),
                                                                                                    sessionResponse: sessionResponse)),
                              siteID: siteID, deviceID: UUID().uuidString)
    }

    /// Builds a `NetworkError` whose `errorCode` resolves from a `{"code": ...}` response body.
    func networkError(statusCode: Int, code: String? = nil) -> NetworkError {
        let response = code.map { Data("{\"code\":\"\($0)\"}".utf8) }
        switch statusCode {
        case 404:
            return .notFound(response: response)
        default:
            return .unacceptableStatusCode(statusCode: statusCode, response: response)
        }
    }
}

private struct UnexpectedCallError: Error {}

private final class MockPOSCashSessionRemote: POSCashSessionRemoteProtocol {
    private let listError: Error
    private let closeError: Error?
    private let sessionResponse: POSCashSessionResponse?
    private let sessionError: Error?
    private let movementResponse: POSCashMovementResponse?
    private let movementResponses: [POSCashMovementResponse]
    private let drawerEventResponse: POSCashDrawerEventResponse?
    private(set) var recordedMovementRequestIDs: [UUID] = []
    private(set) var recordedDrawerEventSessionIDs: [Int64] = []

    init(listError: Error, closeError: Error? = nil, sessionResponse: POSCashSessionResponse? = nil,
         sessionError: Error? = nil, movementResponse: POSCashMovementResponse? = nil,
         movementResponses: [POSCashMovementResponse] = [], drawerEventResponse: POSCashDrawerEventResponse? = nil) {
        self.listError = listError
        self.closeError = closeError
        self.sessionResponse = sessionResponse
        self.sessionError = sessionError
        self.movementResponse = movementResponse
        self.movementResponses = movementResponses
        self.drawerEventResponse = drawerEventResponse
    }

    func listSessions(siteID: Int64, deviceID: String?, status: String, page: Int, perPage: Int) async throws -> PagedItems<POSCashSessionResponse> {
        throw listError
    }

    func session(siteID: Int64, id: Int64) async throws -> POSCashSessionResponse {
        if let sessionError { throw sessionError }
        guard let sessionResponse else { throw UnexpectedCallError() }
        return sessionResponse
    }

    func movements(siteID: Int64, sessionID: Int64, page: Int, perPage: Int) async throws -> PagedItems<POSCashMovementResponse> {
        guard sessionResponse != nil else { throw UnexpectedCallError() }
        return PagedItems(items: movementResponses, hasMorePages: false, totalItems: movementResponses.count)
    }

    func openSession(siteID: Int64, requestID: UUID, deviceID: String, openingAmount: String,
                     drawerID: String?) async throws -> POSCashSessionResponse {
        throw UnexpectedCallError()
    }

    func recordMovement(siteID: Int64, sessionID: Int64, requestID: UUID, type: String,
                        amount: String, reason: String) async throws -> POSCashMovementResponse {
        recordedMovementRequestIDs.append(requestID)
        guard let movementResponse else { throw UnexpectedCallError() }
        return movementResponse
    }

    func recordDrawerEvent(siteID: Int64, sessionID: Int64, requestID: UUID, type: String, reason: String,
                           orderID: Int64?, occurredAt: String, correlationID: UUID?) async throws -> POSCashDrawerEventResponse {
        recordedDrawerEventSessionIDs.append(sessionID)
        guard let drawerEventResponse else { throw UnexpectedCallError() }
        return drawerEventResponse
    }

    func recordCashSale(siteID: Int64, sessionID: Int64, requestID: UUID, orderID: Int64) async throws -> POSCashMovementResponse {
        throw UnexpectedCallError()
    }

    func recordCashRefund(siteID: Int64, sessionID: Int64, requestID: UUID, orderID: Int64,
                          refundID: Int64) async throws -> POSCashMovementResponse {
        throw UnexpectedCallError()
    }

    func closeSession(siteID: Int64, sessionID: Int64, requestID: UUID, expectedRevision: Int,
                      countedAmount: String, note: String?) async throws -> POSCashSessionResponse {
        if let closeError { throw closeError }
        throw UnexpectedCallError()
    }
}
