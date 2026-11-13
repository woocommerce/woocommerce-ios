import Foundation
import Testing

@testable import Yosemite
import Networking

struct CommonReaderConfigProviderTests {

    @Test func fetchDefaultLocationID_returns_incompleteStoreAddress_error_when_jetpack_site_has_incomplete_store_address() async throws {
        let adminURL = "https://example.com/wp-admin/set-address"
        let mockRemote = MockCardReaderCapableRemote(
            resultForDefaultReaderLocation: .failure(
                DotcomError.unknown(code: "store_address_is_incomplete",
                                    message: adminURL,
                                    data: nil)))

        let sut = CommonReaderConfigProvider(siteID: 123,
                                             readerConfigRemote: mockRemote)

        let expectedError = CardReaderConfigError.incompleteStoreAddress(adminUrl: URL(string: adminURL)!)
        await #expect(throws: expectedError) {
            try await withCheckedThrowingContinuation { continuation in
                sut.fetchDefaultLocationID { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

    @Test func fetchDefaultLocationID_returns_invalidPostalCode_error_when_jetpack_site_has_no_postcode() async throws {
        let mockRemote = MockCardReaderCapableRemote(
            resultForDefaultReaderLocation: .failure(
                DotcomError.unknown(code: "postal_code_invalid",
                                    message: "",
                                    data: nil)))

        let sut = CommonReaderConfigProvider(siteID: 123,
                                             readerConfigRemote: mockRemote)

        await #expect(throws: CardReaderConfigError.invalidPostalCode) {
            try await withCheckedThrowingContinuation { continuation in
                sut.fetchDefaultLocationID { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

    @Test(
        .bug("https://github.com/woocommerce/woocommerce-ios/issues/14333", id: "14333")
    )
    func fetchDefaultLocationID_returns_incompleteStoreAddress_error_when_site_has_incomplete_store_address_and_siteCredentials_used() async throws {
        let errorResponseJSON = """
{"code":"store_address_is_incomplete","message":"https://example.com/wp-admin/admin.php?page=wc-settings&tab=general","data":null}
"""
        let mockRemote = MockCardReaderCapableRemote(
            resultForDefaultReaderLocation: .failure(
                NetworkError.unacceptableStatusCode(
                    statusCode: 500,
                    response: errorResponseJSON.data(using: .utf8)
                )
                )
            )

        let sut = CommonReaderConfigProvider(siteID: 123,
                                             readerConfigRemote: mockRemote)

        let expectedError = CardReaderConfigError.incompleteStoreAddress(
            adminUrl: URL(string: "https://example.com/wp-admin/admin.php?page=wc-settings&tab=general")!)
        await #expect(throws: expectedError) {
            try await withCheckedThrowingContinuation { continuation in
                sut.fetchDefaultLocationID { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

    @Test
    func fetchDefaultLocationID_returns_incompleteStoreAddress_error_when_site_has_incomplete_store_address_without_url_and_siteCredentials_used() async throws {
        let errorResponseJSON = """
{"code":"store_address_is_incomplete","message":null,"data":null}
"""
        let mockRemote = MockCardReaderCapableRemote(
            resultForDefaultReaderLocation: .failure(
                NetworkError.unacceptableStatusCode(
                    statusCode: 500,
                    response: errorResponseJSON.data(using: .utf8)
                )
                )
            )

        let sut = CommonReaderConfigProvider(siteID: 123,
                                             readerConfigRemote: mockRemote)

        let expectedError = CardReaderConfigError.incompleteStoreAddress(adminUrl: nil)
        await #expect(throws: expectedError) {
            try await withCheckedThrowingContinuation { continuation in
                sut.fetchDefaultLocationID { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

    @Test(
        .bug("https://github.com/woocommerce/woocommerce-ios/issues/14333", id: "14333")
    )
    func fetchDefaultLocationID_returns_invalidPostalCode_error_when_site_has_no_postcode_and_siteCredentials_used() async throws {
        let errorResponseJSON = """
{"code":"postal_code_invalid"}
"""
        let mockRemote = MockCardReaderCapableRemote(
            resultForDefaultReaderLocation: .failure(
                NetworkError.unacceptableStatusCode(
                    statusCode: 500,
                    response: errorResponseJSON.data(using: .utf8)
                )
                )
            )

        let sut = CommonReaderConfigProvider(siteID: 123,
                                             readerConfigRemote: mockRemote)

        let expectedError = CardReaderConfigError.invalidPostalCode
        await #expect(throws: expectedError) {
            try await withCheckedThrowingContinuation { continuation in
                sut.fetchDefaultLocationID { result in
                    continuation.resume(with: result)
                }
            }
        }
    }

    @Test func fetchDefaultLocationID_when_fetch_succeeds_then_tracks_card_reader_location_success() async throws {
        // Given
        let analytics = MockAnalytics()
        let mockRemote = MockCardReaderCapableRemote(resultForDefaultReaderLocation: .success(.fake()))
        let sut = CommonReaderConfigProvider(siteID: 123, readerConfigRemote: mockRemote, analytics: analytics)

        // When
        _ = try await withCheckedThrowingContinuation { continuation in
            sut.fetchDefaultLocationID { result in
                continuation.resume(with: result)
            }
        }

        // Then
        let event = analytics.trackedEvents.first { $0.eventName == "card_reader_location_success" }
        #expect(event != nil)
        #expect(event?.properties?["site_id"] as? String == "123")
    }

    @Test func fetchDefaultLocationID_when_store_address_incomplete_then_tracks_failure_with_incomplete_store_address_reason() async throws {
        // Given
        let analytics = MockAnalytics()
        let mockRemote = MockCardReaderCapableRemote(resultForDefaultReaderLocation: .failure(
            DotcomError.unknown(code: "store_address_is_incomplete", message: "https://example.com", data: nil)))
        let sut = CommonReaderConfigProvider(siteID: 123, readerConfigRemote: mockRemote, analytics: analytics)

        // When
        _ = await withCheckedContinuation { continuation in
            sut.fetchDefaultLocationID { result in
                continuation.resume(returning: result)
            }
        }

        // Then
        let event = analytics.trackedEvents.first { $0.eventName == "card_reader_location_failure" }
        #expect(event?.properties?["reason"] as? String == "incomplete_store_address")
        #expect(event?.properties?["site_id"] as? String == "123")
    }

    @Test func fetchDefaultLocationID_when_postal_code_invalid_then_tracks_failure_with_invalid_postal_code_reason() async throws {
        // Given
        let analytics = MockAnalytics()
        let mockRemote = MockCardReaderCapableRemote(resultForDefaultReaderLocation: .failure(
            DotcomError.unknown(code: "postal_code_invalid", message: "", data: nil)))
        let sut = CommonReaderConfigProvider(siteID: 123, readerConfigRemote: mockRemote, analytics: analytics)

        // When
        _ = await withCheckedContinuation { continuation in
            sut.fetchDefaultLocationID { result in
                continuation.resume(returning: result)
            }
        }

        // Then
        let event = analytics.trackedEvents.first { $0.eventName == "card_reader_location_failure" }
        #expect(event?.properties?["reason"] as? String == "invalid_postal_code")
    }

    @Test func fetchDefaultLocationID_when_fetch_fails_with_unrelated_error_then_tracks_failure_with_other_reason() async throws {
        // Given
        let analytics = MockAnalytics()
        let mockRemote = MockCardReaderCapableRemote(resultForDefaultReaderLocation: .failure(
            DotcomError.unknown(code: "some_unrelated_error", message: nil, data: nil)))
        let sut = CommonReaderConfigProvider(siteID: 123, readerConfigRemote: mockRemote, analytics: analytics)

        // When
        _ = await withCheckedContinuation { continuation in
            sut.fetchDefaultLocationID { result in
                continuation.resume(returning: result)
            }
        }

        // Then
        let event = analytics.trackedEvents.first { $0.eventName == "card_reader_location_failure" }
        #expect(event?.properties?["reason"] as? String == "other")
    }

    @Test func resetContext_clears_siteID_and_remote() {
        let mockRemote = MockCardReaderCapableRemote(resultForDefaultReaderLocation: .success(.fake()))
        let sut = CommonReaderConfigProvider(siteID: 123, readerConfigRemote: mockRemote)

        sut.resetContext()

        #expect(sut.siteID == nil)
        #expect(sut.readerConfigRemote == nil)
    }
}
