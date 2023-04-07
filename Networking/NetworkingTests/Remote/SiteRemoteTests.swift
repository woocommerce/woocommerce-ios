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
        }, errorAssert: { ($0 as? NetworkError) == .notFound })
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
        }, errorAssert: { ($0 as? NetworkError) == .notFound })
    }

    // MARK: - `enableFreeTrial`

    func test_enableFreeTrial_with_profiler_data_returns_on_success() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "ecommerce-trial/add/ecommerce-trial-bundle-monthly", filename: "site-enable-trial-success")

        // When
        try await remote.enableFreeTrial(siteID: 134, profilerData: .init(name: "Woo shop",
                                                                          category: nil,
                                                                          categoryGroup: nil,
                                                                          sellingStatus: .alreadySellingOnline,
                                                                          sellingPlatforms: "wordPress",
                                                                          countryCode: "US"))
    }

    func test_enableFreeTrial_with_full_profiler_data_sets_all_parameters() async throws {
        // When
        try? await remote.enableFreeTrial(siteID: 134, profilerData: .init(name: "Woo shop",
                                                                           category: "auto_services",
                                                                           categoryGroup: "other",
                                                                           sellingStatus: .alreadySellingOnline,
                                                                           sellingPlatforms: "wordPress",
                                                                           countryCode: "US"))

        // Then
        let parameterDictionary = try XCTUnwrap(network.queryParametersDictionary)
        let onboardingDictionary = try XCTUnwrap(parameterDictionary["wpcom_woocommerce_onboarding"] as? [String: Any])
        XCTAssertEqual(onboardingDictionary["blogname"] as? String, "Woo shop")
        XCTAssertEqual(onboardingDictionary["woocommerce_default_country"] as? String, "US")
        let profilerDictionary = try XCTUnwrap(onboardingDictionary["woocommerce_onboarding_profile"] as? [String: Any])
        XCTAssertEqual(profilerDictionary["is_store_country_set"] as? Bool, true)
        XCTAssertEqual(profilerDictionary["selling_venues"] as? String, "other")
        XCTAssertEqual(profilerDictionary["other_platform"] as? String, "wordPress")
        let profilerIndustryDictionary = try XCTUnwrap(profilerDictionary["industry"] as? [[String: String]])
        XCTAssertEqual(profilerIndustryDictionary, [["slug": "other", "detail": "auto_services"]])
    }

    func test_enableFreeTrial_with_partial_profiler_industry_data_sets_one_industry_parameter() async throws {
        // When
        try? await remote.enableFreeTrial(siteID: 134, profilerData: .init(name: "Woo shop",
                                                                           category: nil, // Category is `nil`.
                                                                           categoryGroup: "other",
                                                                           sellingStatus: .alreadySellingOnline,
                                                                           sellingPlatforms: "wordPress",
                                                                           countryCode: "US"))

        // Then
        let parameterDictionary = try XCTUnwrap(network.queryParametersDictionary)
        let onboardingDictionary = try XCTUnwrap(parameterDictionary["wpcom_woocommerce_onboarding"] as? [String: Any])
        let profilerDictionary = try XCTUnwrap(onboardingDictionary["woocommerce_onboarding_profile"] as? [String: Any])
        let profilerIndustryDictionary = try XCTUnwrap(profilerDictionary["industry"] as? [[String: String]])
        XCTAssertEqual(profilerIndustryDictionary, [["slug": "other"]])
    }

    func test_enableFreeTrial_with_nil_selling_status_does_not_contain_selling_status_parameters() async throws {
        // When
        try? await remote.enableFreeTrial(siteID: 134, profilerData: .init(name: "Woo shop",
                                                                           category: nil, // Category is `nil`.
                                                                           categoryGroup: "other",
                                                                           sellingStatus: nil,
                                                                           sellingPlatforms: nil,
                                                                           countryCode: "US"))

        // Then
        let parameterDictionary = try XCTUnwrap(network.queryParametersDictionary)
        let onboardingDictionary = try XCTUnwrap(parameterDictionary["wpcom_woocommerce_onboarding"] as? [String: Any])
        let profilerDictionary = try XCTUnwrap(onboardingDictionary["woocommerce_onboarding_profile"] as? [String: Any])
        XCTAssertFalse(profilerDictionary.keys.contains("selling_venues"))
        XCTAssertFalse(profilerDictionary.keys.contains("other_platform"))
    }

    func test_enableFreeTrial_returns_DotcomError_failure_on_already_upgraded_error() async throws {
        // Given
        network.simulateResponse(requestUrlSuffix: "ecommerce-trial/add/ecommerce-trial-bundle-monthly", filename: "site-enable-trial-error-already-upgraded")

        await assertThrowsError({
            // When
            try await remote.enableFreeTrial(siteID: 134, profilerData: .init(name: "Woo shop",
                                                                              category: nil,
                                                                              categoryGroup: nil,
                                                                              sellingStatus: .alreadySellingOnline,
                                                                              sellingPlatforms: "wordPress",
                                                                              countryCode: "US"))
        }, errorAssert: { error in
            (error as? DotcomError) == .unknown(code: "no-upgrades-permitted",
                                                message: "You cannot add WordPress.com eCommerce Trial when you already have paid upgrades")
        })
    }
}
