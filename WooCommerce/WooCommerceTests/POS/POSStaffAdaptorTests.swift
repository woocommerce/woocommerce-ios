import Foundation
import Testing
import enum Networking.NetworkError
import enum NetworkingCore.DotcomError
import struct Networking.POSStaffMember
import protocol Networking.POSStaffRemoteProtocol
import enum PointOfSale.POSStaffFetchError
@testable import WooCommerce

struct POSStaffAdaptorTests {
    private let siteID: Int64 = 123

    // MARK: - Success

    @Test func test_fetchStaff_when_remote_succeeds_then_returns_members() async throws {
        // Given
        let members = [makeMember(userID: 1), makeMember(userID: 2)]
        let sut = makeSUT(.success(members))

        // When
        let result = try await sut.fetchStaff(siteID: siteID)

        // Then
        #expect(result == members)
    }

    // MARK: - DecodingError

    @Test func test_fetchStaff_when_remote_throws_decoding_error_then_malformedResponse() async {
        // Given
        let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "bad shape"))
        let sut = makeSUT(.failure(decodingError))

        // Then
        await #expect(throws: POSStaffFetchError.malformedResponse) {
            // When
            _ = try await sut.fetchStaff(siteID: self.siteID)
        }
    }

    // MARK: - DotcomError mapping (Jetpack-tunnelled path)

    @Test func test_fetchStaff_when_dotcom_unauthorized_then_adminMissingCapability() async {
        await expect(.adminMissingCapability, forRemoteError: DotcomError.unauthorized())
    }

    @Test func test_fetchStaff_when_dotcom_invalidToken_then_adminMissingCapability() async {
        await expect(.adminMissingCapability, forRemoteError: DotcomError.invalidToken())
    }

    @Test func test_fetchStaff_when_dotcom_noRestRoute_then_endpointUnavailable() async {
        await expect(.endpointUnavailable, forRemoteError: DotcomError.noRestRoute())
    }

    @Test func test_fetchStaff_when_dotcom_unknown_rest_forbidden_then_adminMissingCapability() async {
        await expect(.adminMissingCapability,
                     forRemoteError: DotcomError.unknown(code: "rest_forbidden", message: nil, data: nil))
    }

    @Test func test_fetchStaff_when_dotcom_other_then_transient_retryable() async {
        await expect(.transient(retryable: true), forRemoteError: DotcomError.requestFailed())
    }

    // MARK: - NetworkError mapping (direct REST path)

    @Test func test_fetchStaff_when_network_notFound_rest_no_route_then_endpointUnavailable() async {
        await expect(.endpointUnavailable,
                     forRemoteError: networkError(statusCode: 404, code: "rest_no_route"))
    }

    @Test func test_fetchStaff_when_network_woocommerce_rest_cannot_code_then_adminMissingCapability() async {
        await expect(.adminMissingCapability,
                     forRemoteError: networkError(statusCode: 403, code: "woocommerce_rest_cannot_view"))
    }

    @Test func test_fetchStaff_when_network_rest_forbidden_code_then_adminMissingCapability() async {
        await expect(.adminMissingCapability,
                     forRemoteError: networkError(statusCode: 403, code: "rest_forbidden"))
    }

    @Test func test_fetchStaff_when_network_status_403_without_code_then_adminMissingCapability() async {
        await expect(.adminMissingCapability, forRemoteError: networkError(statusCode: 403))
    }

    @Test func test_fetchStaff_when_network_status_401_without_code_then_adminMissingCapability() async {
        await expect(.adminMissingCapability, forRemoteError: networkError(statusCode: 401))
    }

    @Test func test_fetchStaff_when_network_status_500_then_transient_retryable() async {
        await expect(.transient(retryable: true), forRemoteError: networkError(statusCode: 500))
    }

    @Test func test_fetchStaff_when_network_timeout_then_transient_retryable() async {
        await expect(.transient(retryable: true), forRemoteError: networkError(statusCode: 408))
    }

    @Test func test_fetchStaff_when_network_notFound_without_rest_no_route_then_transient_retryable() async {
        // A 404 that is not the `rest_no_route` body is treated as transient, not endpointUnavailable.
        await expect(.transient(retryable: true), forRemoteError: networkError(statusCode: 404))
    }

    // MARK: - Unrecognised errors

    @Test func test_fetchStaff_when_remote_throws_unknown_error_then_transient_retryable() async {
        await expect(.transient(retryable: true), forRemoteError: AnonymousError())
    }
}

// MARK: - Helpers

private extension POSStaffAdaptorTests {
    func makeSUT(_ result: Result<[POSStaffMember], Error>) -> POSStaffAdaptor {
        POSStaffAdaptor(remote: MockPOSStaffRemote(result: result))
    }

    /// Asserts the adaptor maps `remoteError` thrown by the remote to `expected`.
    func expect(_ expected: POSStaffFetchError,
                forRemoteError remoteError: Error,
                sourceLocation: SourceLocation = #_sourceLocation) async {
        let sut = makeSUT(.failure(remoteError))
        await #expect(throws: expected, sourceLocation: sourceLocation) {
            _ = try await sut.fetchStaff(siteID: self.siteID)
        }
    }

    func makeMember(userID: Int64) -> POSStaffMember {
        POSStaffMember(userID: userID,
                       displayName: "User \(userID)",
                       preset: "pos_cashier",
                       capabilities: ["pos_process_payments": true],
                       pin: nil)
    }

    /// Builds a `NetworkError` whose `errorCode` resolves from a `{"code": ...}` response body.
    func networkError(statusCode: Int, code: String? = nil) -> NetworkError {
        let response = code.map { Data("{\"code\":\"\($0)\"}".utf8) }
        switch statusCode {
        case 404:
            return .notFound(response: response)
        case 408:
            return .timeout(response: response)
        default:
            return .unacceptableStatusCode(statusCode: statusCode, response: response)
        }
    }
}

private struct AnonymousError: Error {}

private final class MockPOSStaffRemote: POSStaffRemoteProtocol {
    private let result: Result<[POSStaffMember], Error>

    init(result: Result<[POSStaffMember], Error>) {
        self.result = result
    }

    func fetchStaff(siteID: Int64) async throws -> [POSStaffMember] {
        try result.get()
    }
}
