import Foundation
import class Yosemite.POSCashSessionRemoteService
import struct Yosemite.POSCashSessionAPIError
import Testing
import enum Networking.NetworkError
import enum NetworkingCore.DotcomError
import struct NetworkingCore.PagedItems
import struct Networking.POSCashSessionResponse
import struct Networking.POSCashMovementResponse
import protocol Networking.POSCashSessionRemoteProtocol
import enum PointOfSale.POSCashSessionServiceError
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

    init(listError: Error, closeError: Error? = nil, sessionResponse: POSCashSessionResponse? = nil) {
        self.listError = listError
        self.closeError = closeError
        self.sessionResponse = sessionResponse
    }

    func listSessions(siteID: Int64, deviceID: String?, status: String, page: Int, perPage: Int) async throws -> PagedItems<POSCashSessionResponse> {
        throw listError
    }

    func session(siteID: Int64, id: Int64) async throws -> POSCashSessionResponse {
        guard let sessionResponse else { throw UnexpectedCallError() }
        return sessionResponse
    }

    func movements(siteID: Int64, sessionID: Int64, page: Int, perPage: Int) async throws -> PagedItems<POSCashMovementResponse> {
        guard sessionResponse != nil else { throw UnexpectedCallError() }
        return PagedItems(items: [], hasMorePages: false, totalItems: 0)
    }

    func openSession(siteID: Int64, requestID: UUID, deviceID: String, openingAmount: String) async throws -> POSCashSessionResponse {
        throw UnexpectedCallError()
    }

    func recordMovement(siteID: Int64, sessionID: Int64, requestID: UUID, type: String,
                        amount: String, reason: String) async throws -> POSCashMovementResponse {
        throw UnexpectedCallError()
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
