import XCTest
import TestKit
@testable import Networking

final class SiteRemoteTests: XCTestCase {
    /// Mock network wrapper.
    private var network: MockNetwork!

    private var remote: SiteRemote!

    override func setUp() {
        super.setUp()
        network = MockNetwork()
        remote = SiteRemote(network: network, dotcomClientID: "", dotcomClientSecret: "")
    }

    override func tearDown() {
        remote = nil
        network = nil
        super.tearDown()
    }

    // MARK: - `createSite`

    func test_createSite_returns_created_site_on_success() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "sites/new", filename: "site-creation-success")

        // When
        let response = try await remote.createSite(name: "Wapuu swags", flow: .onboarding(domain: "wapuu.store"))

        // Then
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.site, .init(siteID: "202211",
                                            name: "Wapuu swags",
                                            url: "https://wapuu.store/",
                                            siteSlug: "wapuu.store"))
    }

    func test_createSite_returns_invalidDomain_error_when_domain_is_empty() async throws {
        await assertThrowsError({ _ = try await remote.createSite(name: "Wapuu swags", flow: .onboarding(domain: "")) },
                                errorAssert: { ($0 as? SiteCreationError) == .invalidDomain} )
    }

    func test_createSite_returns_DotcomError_failure_on_domain_error() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "sites/new", filename: "site-creation-domain-error")

        await assertThrowsError({
            // When
            _ = try await remote.createSite(name: "Wapuu swags", flow: .onboarding(domain: "wapuu.store"))
        }, errorAssert: { ($0 as? DotcomError) == .unknown(code: "blog_name_only_lowercase_letters_and_numbers",
                                                message: "Site names can only contain lowercase letters (a-z) and numbers.")
        })
    }

    func test_createSite_returns_failure_on_empty_response() async throws {
        await assertThrowsError({
            // When
            _ = try await remote.createSite(name: "Wapuu swags", flow: .onboarding(domain: "wapuu.store"))
        }, errorAssert: { ($0 as? NetworkError) == .notFound() })
    }

    // MARK: - `launchSite`

    func test_launchSite_returns_on_success() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "launch", filename: "site-launch-success")

        // When
        do {
            try await remote.launchSite(siteID: 134)
        } catch {
            // Then
            XCTFail("Unexpected failure launching site: \(error)")
        }
    }

    func test_launchSite_returns_DotcomError_failure_on_already_launched_error() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "launch", filename: "site-launch-error-already-launched")

        await assertThrowsError({
            // When
            try await remote.launchSite(siteID: 134)
        }, errorAssert: {
            ($0 as? WordPressApiError) == .unknown(code: "already-launched",
                                                   message: "This site has already been launched")
        })
    }

    func test_launchSite_returns_WordPressApiError_failure_on_unauthorized_error() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "launch", filename: "site-launch-error-unauthorized")

        await assertThrowsError({
            // When
            try await remote.launchSite(siteID: 134)
        }, errorAssert: {
            ($0 as? WordPressApiError) == .unknown(code: "unauthorized",
                                                   message: "You do not have permission to launch this site.")
        })
    }

    func test_launchSite_returns_failure_on_empty_response() async throws {
        await assertThrowsError({
            // When
            _ = try await remote.launchSite(siteID: 134)
        }, errorAssert: { ($0 as? NetworkError) == .notFound() })
    }

    // MARK: - `enableFreeTrial`

    func test_enableFreeTrial_with_profiler_data_returns_on_success() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "ecommerce-trial/add/ecommerce-trial-bundle-monthly", filename: "site-enable-trial-success")

        // When
        try await remote.enableFreeTrial(siteID: 134)
    }

    func test_enableFreeTrial_returns_DotcomError_failure_on_already_upgraded_error() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "ecommerce-trial/add/ecommerce-trial-bundle-monthly", filename: "site-enable-trial-error-already-upgraded")

        await assertThrowsError({
            // When
            try await remote.enableFreeTrial(siteID: 134)
        }, errorAssert: { error in
            (error as? DotcomError) == .unknown(code: "no-upgrades-permitted",
                                                message: "You cannot add WordPress.com eCommerce Trial when you already have paid upgrades")
        })
    }

    // MARK: - `updateSiteTitle`
    func test_updateSiteTitle_returns_on_success() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "settings", filename: "site-settings-success")

        // When
        try await remote.updateSiteTitle(siteID: 123, title: "Test")
    }

    func test_updateSiteTitle_returns_failure_on_empty_response() async throws {
        await assertThrowsError({
            // When
            _ = try await remote.updateSiteTitle(siteID: 123, title: "Test")
        }, errorAssert: { ($0 as? NetworkError) == .notFound() })
    }

    // MARK: - `uploadStoreProfilerAnswers`

    func test_uploadStoreProfilerAnswers_with_profiler_data_returns_on_success() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "options", filename: "site-upload-profiler-answers-success")

        // When
        try await remote.uploadStoreProfilerAnswers(siteID: 134,
                                                    answers: .init(sellingStatus: .alreadySellingOnline,
                                                                   sellingPlatforms: "wordpress",
                                                                   category: "clothing_and_accessories",
                                                                   countryCode: "US"))
    }

    func test_uploadStoreProfilerAnswers_with_full_profiler_data_sets_all_parameters() async throws {
        // When
        try? await remote.uploadStoreProfilerAnswers(siteID: 134,
                                                     answers: .init(sellingStatus: .alreadySellingOnline,
                                                                    sellingPlatforms: "wordpress",
                                                                    category: "clothing_and_accessories",
                                                                    countryCode: "US"))

        // Then
        let parameterDictionary = try XCTUnwrap(network.queryParametersDictionary)

        XCTAssertEqual(parameterDictionary["woocommerce_default_country"] as? String, "US")
        let profilerDictionary = try XCTUnwrap(parameterDictionary["woocommerce_onboarding_profile"] as? [String: Any])
        XCTAssertEqual(profilerDictionary["is_store_country_set"] as? Bool, true)
        XCTAssertEqual(profilerDictionary["business_choice"] as? String, "im_already_selling")
        XCTAssertEqual(profilerDictionary["selling_platforms"] as? String, "wordpress")
        XCTAssertEqual(try XCTUnwrap(profilerDictionary["industry"] as? [String]), ["clothing_and_accessories"])
    }

    func test_uploadStoreProfilerAnswers_with_nil_category_data_does_not_contain_industry_parameters() async throws {
        // When
        try? await remote.uploadStoreProfilerAnswers(siteID: 134,
                                                     answers: .init(sellingStatus: .alreadySellingOnline,
                                                                    sellingPlatforms: nil,
                                                                    category: nil,
                                                                    countryCode: "US"))

        // Then
        let parameterDictionary = try XCTUnwrap(network.queryParametersDictionary)
        let profilerDictionary = try XCTUnwrap(parameterDictionary["woocommerce_onboarding_profile"] as? [String: Any])
        XCTAssertFalse(profilerDictionary.keys.contains("industry"))
    }

    func test_uploadStoreProfilerAnswers_with_nil_selling_status_does_not_contain_business_choice_parameters() async throws {
        // When
        try? await remote.uploadStoreProfilerAnswers(siteID: 134,
                                                     answers: .init(sellingStatus: nil,
                                                                    sellingPlatforms: "wordpress",
                                                                    category: "clothing_and_accessories",
                                                                    countryCode: "US"))

        // Then
        let parameterDictionary = try XCTUnwrap(network.queryParametersDictionary)
        let profilerDictionary = try XCTUnwrap(parameterDictionary["woocommerce_onboarding_profile"] as? [String: Any])
        XCTAssertFalse(profilerDictionary.keys.contains("business_choice"))
    }

    func test_uploadStoreProfilerAnswers_with_nil_selling_platforms_does_not_contain_selling_platforms_parameters() async throws {
        // When
        try? await remote.uploadStoreProfilerAnswers(siteID: 134,
                                                     answers: .init(sellingStatus: nil,
                                                                    sellingPlatforms: nil,
                                                                    category: "clothing_and_accessories",
                                                                    countryCode: "US"))

        // Then
        let parameterDictionary = try XCTUnwrap(network.queryParametersDictionary)
        let profilerDictionary = try XCTUnwrap(parameterDictionary["woocommerce_onboarding_profile"] as? [String: Any])
        XCTAssertFalse(profilerDictionary.keys.contains("selling_platforms"))
    }

    func test_uploadStoreProfilerAnswers_with_valid_country_sets_is_store_country_set_parameter_as_true() async throws {
        // When
        try? await remote.uploadStoreProfilerAnswers(siteID: 134,
                                                     answers: .init(sellingStatus: nil,
                                                                    sellingPlatforms: "wordpress",
                                                                    category: "clothing_and_accessories",
                                                                    countryCode: "US"))

        // Then
        let parameterDictionary = try XCTUnwrap(network.queryParametersDictionary)
        let profilerDictionary = try XCTUnwrap(parameterDictionary["woocommerce_onboarding_profile"] as? [String: Any])
        XCTAssertTrue(try XCTUnwrap(profilerDictionary["is_store_country_set"] as? Bool))
    }

    func test_uploadStoreProfilerAnswers_with_nil_country_sets_is_store_country_set_parameter_as_false() async throws {
        // When
        try? await remote.uploadStoreProfilerAnswers(siteID: 134,
                                                     answers: .init(sellingStatus: nil,
                                                                    sellingPlatforms: "wordpress",
                                                                    category: "clothing_and_accessories",
                                                                    countryCode: nil))

        // Then
        let parameterDictionary = try XCTUnwrap(network.queryParametersDictionary)
        let profilerDictionary = try XCTUnwrap(parameterDictionary["woocommerce_onboarding_profile"] as? [String: Any])
        XCTAssertFalse(try XCTUnwrap(profilerDictionary["is_store_country_set"] as? Bool))
    }

    func test_uploadStoreProfilerAnswers_with_valid_country_has_woocommerce_default_country_value() async throws {
        // When
        try? await remote.uploadStoreProfilerAnswers(siteID: 134,
                                                     answers: .init(sellingStatus: nil,
                                                                    sellingPlatforms: "wordpress",
                                                                    category: "clothing_and_accessories",
                                                                    countryCode: "US"))

        // Then
        let parameterDictionary = try XCTUnwrap(network.queryParametersDictionary)
        XCTAssertEqual(try XCTUnwrap(parameterDictionary["woocommerce_default_country"] as? String), "US")
    }

    func test_uploadStoreProfilerAnswers_with_nil_country_sets_has_woocommerce_default_country_as_nil() async throws {
        // When
        try? await remote.uploadStoreProfilerAnswers(siteID: 134,
                                                     answers: .init(sellingStatus: nil,
                                                                    sellingPlatforms: "wordpress",
                                                                    category: "clothing_and_accessories",
                                                                    countryCode: nil))

        // Then
        let parameterDictionary = try XCTUnwrap(network.queryParametersDictionary)
        XCTAssertNil(parameterDictionary["woocommerce_default_country"])
    }

    func test_uploadStoreProfilerAnswers_returns_DotcomError_on_failure() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "options", filename: "generic_error")

        await assertThrowsError({
            // When
            try await remote.uploadStoreProfilerAnswers(siteID: 134,
                                                        answers: .init(sellingStatus: nil,
                                                                       sellingPlatforms: "wordpress",
                                                                       category: "clothing_and_accessories",
                                                                       countryCode: "US"))
        }, errorAssert: { error in
            (error as? DotcomError) == .unauthorized
        })
    }
}
