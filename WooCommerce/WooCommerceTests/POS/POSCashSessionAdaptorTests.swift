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
}

private extension POSCashSessionAdaptorTests {
    func makeSUT(listError: Error) -> POSCashSessionAdaptor {
        POSCashSessionAdaptor(remote: POSCashSessionRemoteService(remote: MockPOSCashSessionRemote(listError: listError)),
                              siteID: siteID, deviceID: "device")
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

    init(listError: Error) {
        self.listError = listError
    }

    func listSessions(siteID: Int64, deviceID: String?, status: String, page: Int, perPage: Int) async throws -> PagedItems<POSCashSessionResponse> {
        throw listError
    }

    func session(siteID: Int64, id: Int64) async throws -> POSCashSessionResponse { throw UnexpectedCallError() }

    func movements(siteID: Int64, sessionID: Int64, page: Int, perPage: Int) async throws -> PagedItems<POSCashMovementResponse> {
        throw UnexpectedCallError()
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
        throw UnexpectedCallError()
    }
}
