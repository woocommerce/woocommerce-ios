import XCTest
@testable import WooCommerce
import Networking
import PointOfSale

final class POSStaffAdaptorTests: XCTestCase {

    func test_fetchStaff_when_remote_returns_staff_then_passes_through() async throws {
        // Given
        let staff = [POSStaffMember(userID: 1, userLogin: "u", displayName: "U",
                                    role: "pos_cashier", capabilities: [:], pin: nil)]
        let remote = MockPOSStaffRemote(result: .success(staff))
        let sut = POSStaffAdaptor(remote: remote)

        // When
        let result = try await sut.fetchStaff(siteID: 1)

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.userID, 1)
    }

    func test_fetchStaff_when_remote_returns_noRestRoute_then_throws_flagDisabledServerSide() async {
        // Given
        let error = DotcomError.noRestRoute()
        let remote = MockPOSStaffRemote(result: .failure(error))
        let sut = POSStaffAdaptor(remote: remote)

        // When / Then
        await assertThrows(POSStaffFetchError.flagDisabledServerSide) {
            _ = try await sut.fetchStaff(siteID: 1)
        }
    }

    func test_fetchStaff_when_remote_returns_unauthorized_then_throws_adminMissingCapability() async {
        // Given
        let error = DotcomError.unauthorized()
        let remote = MockPOSStaffRemote(result: .failure(error))
        let sut = POSStaffAdaptor(remote: remote)

        // When / Then
        await assertThrows(POSStaffFetchError.adminMissingCapability) {
            _ = try await sut.fetchStaff(siteID: 1)
        }
    }

    func test_fetchStaff_when_invalidToken_then_throws_adminMissingCapability() async {
        // Given
        let error = DotcomError.invalidToken()
        let remote = MockPOSStaffRemote(result: .failure(error))
        let sut = POSStaffAdaptor(remote: remote)

        // When / Then
        await assertThrows(POSStaffFetchError.adminMissingCapability) {
            _ = try await sut.fetchStaff(siteID: 1)
        }
    }

    func test_fetchStaff_when_rest_forbidden_then_throws_adminMissingCapability() async {
        // Given
        let error = DotcomError.unknown(code: "rest_forbidden", message: nil, data: nil)
        let remote = MockPOSStaffRemote(result: .failure(error))
        let sut = POSStaffAdaptor(remote: remote)

        // When / Then
        await assertThrows(POSStaffFetchError.adminMissingCapability) {
            _ = try await sut.fetchStaff(siteID: 1)
        }
    }

    func test_fetchStaff_when_decoding_fails_then_throws_malformedResponse() async {
        // Given
        let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: ""))
        let remote = MockPOSStaffRemote(result: .failure(decodingError))
        let sut = POSStaffAdaptor(remote: remote)

        // When / Then
        await assertThrows(POSStaffFetchError.malformedResponse) {
            _ = try await sut.fetchStaff(siteID: 1)
        }
    }

    func test_fetchStaff_when_generic_error_then_throws_transient() async {
        // Given
        let error = URLError(.timedOut)
        let remote = MockPOSStaffRemote(result: .failure(error))
        let sut = POSStaffAdaptor(remote: remote)

        // When / Then
        await assertThrows(POSStaffFetchError.transient(retryable: true)) {
            _ = try await sut.fetchStaff(siteID: 1)
        }
    }

    func test_fetchStaff_when_wc_rest_cannot_view_then_throws_adminMissingCapability() async {
        // Given - the actual error WC returns on 401 (verified live against staging)
        let error = WordPressApiError.unknown(code: "woocommerce_rest_cannot_view",
                                              message: "Sorry, you cannot view resources.")
        let remote = MockPOSStaffRemote(result: .failure(error))
        let sut = POSStaffAdaptor(remote: remote)

        // When / Then
        await assertThrows(POSStaffFetchError.adminMissingCapability) {
            _ = try await sut.fetchStaff(siteID: 1)
        }
    }

    func test_fetchStaff_when_wc_rest_other_error_then_throws_transient() async {
        // Given - a non-auth WC error should not silently map to admin-missing-cap
        let error = WordPressApiError.unknown(code: "woocommerce_rest_invalid_id",
                                              message: "Invalid resource ID.")
        let remote = MockPOSStaffRemote(result: .failure(error))
        let sut = POSStaffAdaptor(remote: remote)

        // When / Then
        await assertThrows(POSStaffFetchError.transient(retryable: true)) {
            _ = try await sut.fetchStaff(siteID: 1)
        }
    }

    // MARK: - Helpers

    private func assertThrows<E: Error & Equatable>(_ expected: E, _ block: () async throws -> Void) async {
        do {
            try await block()
            XCTFail("Expected \(expected) to be thrown")
        } catch let actual as E {
            XCTAssertEqual(actual, expected)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}

// MARK: - Mock

private final class MockPOSStaffRemote: POSStaffRemoteProtocol {
    private let result: Result<[POSStaffMember], Error>

    init(result: Result<[POSStaffMember], Error>) {
        self.result = result
    }

    func fetchStaff(siteID: Int64) async throws -> [POSStaffMember] {
        try result.get()
    }
}
