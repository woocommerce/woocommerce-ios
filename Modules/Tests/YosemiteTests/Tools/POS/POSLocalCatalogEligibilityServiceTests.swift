import Foundation
import Testing
@testable import Yosemite

@Suite("POSLocalCatalogEligibilityService Tests")
@MainActor
struct POSLocalCatalogEligibilityServiceTests {
    private let siteID: Int64 = 123

    // Default remote feature flag provider that returns true
    private func makeRemoteFeatureFlagProvider(returning value: Bool = true) -> @Sendable () async -> Bool {
        return { value }
    }

    // Default beta feature toggle provider that returns true
    private func makeBetaFeatureToggleProvider(returning value: Bool = true) -> @Sendable () async -> Bool {
        return { value }
    }

    // MARK: - Catalog Size Within Limit

    @Test("Catalog size within limit returns eligible")
    func testCatalogSizeWithinLimitReturnsEligible() async throws {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 500, variationCount: 400))
        )
        let systemStatusService = MockPOSSystemStatusService()
        let service = POSLocalCatalogEligibilityService(
            catalogSizeChecker: sizeChecker,
            systemStatusService: systemStatusService,
            remoteFeatureFlagProvider: makeRemoteFeatureFlagProvider(),
            betaFeatureToggleProvider: makeBetaFeatureToggleProvider(),
            catalogSizeLimit: 1000
        )
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        #expect(try await service.catalogEligibility(for: siteID) == .eligible)
    }

    @Test("Exactly at size limit returns eligible")
    func testExactlyAtSizeLimitReturnsEligible() async throws {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 600, variationCount: 400))
        )
        let systemStatusService = MockPOSSystemStatusService()
        let service = POSLocalCatalogEligibilityService(
            catalogSizeChecker: sizeChecker,
            systemStatusService: systemStatusService,
            remoteFeatureFlagProvider: makeRemoteFeatureFlagProvider(),
            betaFeatureToggleProvider: makeBetaFeatureToggleProvider(),
            catalogSizeLimit: 1000
        )
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        #expect(try await service.catalogEligibility(for: siteID) == .eligible)
    }

    // MARK: - Catalog Size Exceeds Limit

    @Test("Catalog one over limit returns ineligible")
    func testCatalogOneOverLimitReturnsIneligible() async throws {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 501, variationCount: 500))
        )
        let systemStatusService = MockPOSSystemStatusService()
        let service = POSLocalCatalogEligibilityService(
            catalogSizeChecker: sizeChecker,
            systemStatusService: systemStatusService,
            remoteFeatureFlagProvider: makeRemoteFeatureFlagProvider(),
            betaFeatureToggleProvider: makeBetaFeatureToggleProvider(),
            catalogSizeLimit: 1000
        )
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        let state = try await service.catalogEligibility(for: siteID)

        guard case .ineligible(let reason) = state else {
            Issue.record("Expected ineligible state")
            return
        }

        guard case .catalogSizeTooLarge(let totalCount, let limit) = reason else {
            Issue.record("Expected catalogSizeTooLarge reason")
            return
        }

        #expect(totalCount == 1001)
        #expect(limit == 1000)
    }

    // MARK: - Catalog Size Check Failure

    @Test("Catalog size check failure returns ineligible")
    func testCatalogSizeCheckFailureReturnsIneligible() async throws {
        let expectedError = NSError(domain: "test", code: 123, userInfo: nil)
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .failure(expectedError)
        )
        let systemStatusService = MockPOSSystemStatusService()
        let service = POSLocalCatalogEligibilityService(
            catalogSizeChecker: sizeChecker,
            systemStatusService: systemStatusService,
            remoteFeatureFlagProvider: makeRemoteFeatureFlagProvider(),
            betaFeatureToggleProvider: makeBetaFeatureToggleProvider(),
            catalogSizeLimit: 1000
        )
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        let state = try await service.catalogEligibility(for: siteID)

        guard case .ineligible(let reason) = state else {
            Issue.record("Expected ineligible state")
            return
        }

        guard case .catalogSizeCheckFailed(let errorString) = reason else {
            Issue.record("Expected catalogSizeCheckFailed reason")
            return
        }

        #expect(errorString.contains("123"))
    }

    // MARK: - Caching

    @Test("Second call uses cached state")
    func testSecondCallUsesCachedState() async throws {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 500, variationCount: 400))
        )
        let systemStatusService = MockPOSSystemStatusService()
        let service = POSLocalCatalogEligibilityService(
            catalogSizeChecker: sizeChecker,
            systemStatusService: systemStatusService,
            remoteFeatureFlagProvider: makeRemoteFeatureFlagProvider(),
            betaFeatureToggleProvider: makeBetaFeatureToggleProvider(),
            catalogSizeLimit: 1000
        )
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        // First call
        let firstState = try await service.catalogEligibility(for: siteID)
        #expect(firstState == .eligible)
        #expect(sizeChecker.checkCatalogSizeCallCount == 1)

        // Second call should use cache
        let secondState = try await service.catalogEligibility(for: siteID)
        #expect(secondState == .eligible)
        #expect(sizeChecker.checkCatalogSizeCallCount == 1) // Should not increment
    }

    @Test("Refresh bypasses cache")
    func testRefreshBypassesCache() async throws {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 500, variationCount: 400))
        )
        let systemStatusService = MockPOSSystemStatusService()
        let service = POSLocalCatalogEligibilityService(
            catalogSizeChecker: sizeChecker,
            systemStatusService: systemStatusService,
            remoteFeatureFlagProvider: makeRemoteFeatureFlagProvider(),
            betaFeatureToggleProvider: makeBetaFeatureToggleProvider(),
            catalogSizeLimit: 1000
        )
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        // First call
        let firstState = try await service.catalogEligibility(for: siteID)
        #expect(firstState == .eligible)
        #expect(sizeChecker.checkCatalogSizeCallCount == 1)

        // Refresh should fetch again
        let refreshedState = try await service.refreshEligibilityState(for: siteID)
        #expect(refreshedState == .eligible)
        #expect(sizeChecker.checkCatalogSizeCallCount == 2) // Should increment
    }

    @Test("Refresh updates cache")
    func testRefreshUpdatesCache() async throws {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 500, variationCount: 400))
        )
        let systemStatusService = MockPOSSystemStatusService()
        let service = POSLocalCatalogEligibilityService(
            catalogSizeChecker: sizeChecker,
            systemStatusService: systemStatusService,
            remoteFeatureFlagProvider: makeRemoteFeatureFlagProvider(),
            betaFeatureToggleProvider: makeBetaFeatureToggleProvider(),
            catalogSizeLimit: 1000
        )
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        // First call caches eligible state
        _ = try await service.catalogEligibility(for: siteID)
        #expect(sizeChecker.checkCatalogSizeCallCount == 1)

        // Change the size checker to return ineligible
        sizeChecker.sizeToReturn = .success(POSCatalogSize(productCount: 1000, variationCount: 100))

        // Refresh should update cache
        let refreshedState = try await service.refreshEligibilityState(for: siteID)
        guard case .ineligible = refreshedState else {
            Issue.record("Expected ineligible after refresh")
            return
        }
        #expect(sizeChecker.checkCatalogSizeCallCount == 2)

        // Next get should return cached ineligible
        let cachedState = try await service.catalogEligibility(for: siteID)
        guard case .ineligible = cachedState else {
            Issue.record("Expected cached ineligible state")
            return
        }
        #expect(sizeChecker.checkCatalogSizeCallCount == 2) // Should not increment
    }

    // MARK: - Feature Flag

    @Test("Remote feature flag disabled returns ineligible after refresh")
    func testRemoteFeatureFlagDisabledReturnsIneligible() async throws {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 500, variationCount: 400))
        )
        let systemStatusService = MockPOSSystemStatusService()
        let service = POSLocalCatalogEligibilityService(
            catalogSizeChecker: sizeChecker,
            systemStatusService: systemStatusService,
            remoteFeatureFlagProvider: makeRemoteFeatureFlagProvider(returning: false),
            betaFeatureToggleProvider: makeBetaFeatureToggleProvider(),
            catalogSizeLimit: 1000
        )
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        // First refresh might check catalog (using default true before fetch completes)
        _ = try? await service.refreshEligibilityState(for: siteID)

        // Second refresh should use the fetched remote flag value (false)
        let state = try await service.refreshEligibilityState(for: siteID)

        guard case .ineligible(let reason) = state else {
            Issue.record("Expected ineligible state after remote flag fetch")
            return
        }

        guard case .featureFlagDisabled = reason else {
            Issue.record("Expected featureFlagDisabled reason")
            return
        }

        // Second refresh should not have checked catalog size (short-circuited by flag)
        // First refresh might have checked it (count could be 0 or 1)
        #expect(sizeChecker.checkCatalogSizeCallCount <= 1)
    }

    @Test("All feature flags required for eligibility")
    func testAllFeatureFlagsRequiredForEligibility() async throws {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 500, variationCount: 400))
        )
        let systemStatusService = MockPOSSystemStatusService()

        // Test with all flags enabled - should be eligible
        let serviceWithAllEnabled = POSLocalCatalogEligibilityService(
            catalogSizeChecker: sizeChecker,
            systemStatusService: systemStatusService,
            remoteFeatureFlagProvider: makeRemoteFeatureFlagProvider(returning: true),
            betaFeatureToggleProvider: makeBetaFeatureToggleProvider(returning: true),
            catalogSizeLimit: 1000
        )
        try await serviceWithAllEnabled.updatePOSEligibility(isEligible: true, for: siteID)
        #expect(try await serviceWithAllEnabled.catalogEligibility(for: siteID) == .eligible)
    }

    @Test("Beta feature toggle disabled returns ineligible")
    func testBetaFeatureToggleDisabledReturnsIneligible() async throws {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 500, variationCount: 400))
        )
        let systemStatusService = MockPOSSystemStatusService()
        let service = POSLocalCatalogEligibilityService(
            catalogSizeChecker: sizeChecker,
            systemStatusService: systemStatusService,
            remoteFeatureFlagProvider: makeRemoteFeatureFlagProvider(returning: true),
            betaFeatureToggleProvider: makeBetaFeatureToggleProvider(returning: false),
            catalogSizeLimit: 1000
        )
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        let state = try await service.catalogEligibility(for: siteID)

        guard case .ineligible(let reason) = state else {
            Issue.record("Expected ineligible state")
            return
        }

        guard case .featureFlagDisabled = reason else {
            Issue.record("Expected featureFlagDisabled reason")
            return
        }

        // Should not have checked catalog size
        #expect(sizeChecker.checkCatalogSizeCallCount == 0)
    }

    // MARK: - Custom Size Limit

    @Test("Custom size limit is respected")
    func testCustomSizeLimitIsRespected() async throws {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 100, variationCount: 50))
        )
        let systemStatusService = MockPOSSystemStatusService()
        let service = POSLocalCatalogEligibilityService(
            catalogSizeChecker: sizeChecker,
            systemStatusService: systemStatusService,
            remoteFeatureFlagProvider: makeRemoteFeatureFlagProvider(),
            betaFeatureToggleProvider: makeBetaFeatureToggleProvider(),
            catalogSizeLimit: 100 // Custom lower limit
        )
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        let state = try await service.catalogEligibility(for: siteID)

        guard case .ineligible(let reason) = state else {
            Issue.record("Expected ineligible state")
            return
        }

        guard case .catalogSizeTooLarge(let totalCount, let limit) = reason else {
            Issue.record("Expected catalogSizeTooLarge reason")
            return
        }

        #expect(totalCount == 150)
        #expect(limit == 100)
    }

    // MARK: - POS Eligibility

    @Test("POS not eligible returns ineligible")
    func testPOSNotEligibleReturnsIneligible() async throws {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 500, variationCount: 400))
        )
        let systemStatusService = MockPOSSystemStatusService()
        let service = POSLocalCatalogEligibilityService(
            catalogSizeChecker: sizeChecker,
            systemStatusService: systemStatusService,
            remoteFeatureFlagProvider: makeRemoteFeatureFlagProvider(),
            betaFeatureToggleProvider: makeBetaFeatureToggleProvider(),
            catalogSizeLimit: 1000
        )

        // Set POS as not eligible
        try await service.updatePOSEligibility(isEligible: false, for: siteID)

        let state = try await service.catalogEligibility(for: siteID)

        guard case .ineligible(let reason) = state else {
            Issue.record("Expected ineligible state")
            return
        }

        guard case .posTabNotEligible = reason else {
            Issue.record("Expected posTabNotEligible reason")
            return
        }

        // Should not have checked catalog size
        #expect(sizeChecker.checkCatalogSizeCallCount == 0)
    }

    @Test("POS eligibility checked before catalog size")
    func testPOSEligibilityCheckedFirst() async throws {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 2000, variationCount: 0))
        )
        let systemStatusService = MockPOSSystemStatusService()
        let service = POSLocalCatalogEligibilityService(
            catalogSizeChecker: sizeChecker,
            systemStatusService: systemStatusService,
            remoteFeatureFlagProvider: makeRemoteFeatureFlagProvider(),
            betaFeatureToggleProvider: makeBetaFeatureToggleProvider(),
            catalogSizeLimit: 1000
        )

        // Set POS as not eligible
        try await service.updatePOSEligibility(isEligible: false, for: siteID)

        // Should be ineligible due to POS not eligible, not catalog size
        guard case .ineligible(let reason) = try await service.catalogEligibility(for: siteID) else {
            Issue.record("Expected ineligible state")
            return
        }

        guard case .posTabNotEligible = reason else {
            Issue.record("Expected posTabNotEligible reason, not catalogSizeTooLarge")
            return
        }

        // Should not have checked catalog size since POS wasn't eligible
        #expect(sizeChecker.checkCatalogSizeCallCount == 0)
    }

    @Test("POS eligible allows catalog size check")
    func testPOSEligibleAllowsCatalogSizeCheck() async throws {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 500, variationCount: 400))
        )
        let systemStatusService = MockPOSSystemStatusService()
        let service = POSLocalCatalogEligibilityService(
            catalogSizeChecker: sizeChecker,
            systemStatusService: systemStatusService,
            remoteFeatureFlagProvider: makeRemoteFeatureFlagProvider(),
            betaFeatureToggleProvider: makeBetaFeatureToggleProvider(),
            catalogSizeLimit: 1000
        )

        // Set POS as eligible
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        let state = try await service.catalogEligibility(for: siteID)
        #expect(state == .eligible)

        // Should have checked catalog size since POS was eligible
        #expect(sizeChecker.checkCatalogSizeCallCount == 1)
    }

    // MARK: - WooCommerce Version Checking

    @Test("WooCommerce version eligibility",
          arguments: [
            ("10.2.0", true, false, 0),         // Below minimum
            ("10.3.0-beta", true, true, 1),     // At minimum (beta)
            ("10.3.0", true, true, 1),          // At minimum (stable)
            ("11.0.0", true, true, 1),          // Above minimum
          ])
    func testWooCommerceVersionEligibility(
        version: String,
        isActive: Bool,
        expectEligible: Bool,
        expectedSizeCheckCount: Int
    ) async throws {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 500, variationCount: 400))
        )
        let systemStatusService = MockPOSSystemStatusService(
            pluginInfoToReturn: .success(
                POSPluginAndFeatureInfo(
                    wcPlugin: SystemPlugin(
                        siteID: siteID,
                        plugin: "woocommerce/woocommerce.php",
                        name: "WooCommerce",
                        version: version,
                        versionLatest: "11.0.0",
                        url: "https://woocommerce.com",
                        authorName: "WooCommerce",
                        authorUrl: "https://woocommerce.com",
                        networkActivated: false,
                        active: isActive
                    ),
                    featureValue: true
                )
            )
        )
        let service = POSLocalCatalogEligibilityService(
            catalogSizeChecker: sizeChecker,
            systemStatusService: systemStatusService,
            remoteFeatureFlagProvider: makeRemoteFeatureFlagProvider(),
            betaFeatureToggleProvider: makeBetaFeatureToggleProvider(),
            catalogSizeLimit: 1000
        )
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        let state = try await service.catalogEligibility(for: siteID)

        if expectEligible {
            #expect(state == .eligible)
        } else {
            guard case .ineligible(let reason) = state else {
                Issue.record("Expected ineligible state for version \(version)")
                return
            }
            guard case .unsupportedWooCommerceVersion(let minimumVersion) = reason else {
                Issue.record("Expected unsupportedWooCommerceVersion reason for version \(version)")
                return
            }
            #expect(minimumVersion == "10.3.0-beta")
        }
        #expect(sizeChecker.checkCatalogSizeCallCount == expectedSizeCheckCount)
    }

    @Test("WooCommerce plugin states",
          arguments: [
            (nil, POSLocalCatalogIneligibleReason.posTabNotEligible),           // Plugin not found
            (false, POSLocalCatalogIneligibleReason.posTabNotEligible),         // Plugin inactive
          ])
    func testWooCommercePluginStates(
        isActive: Bool?,
        expectedReason: POSLocalCatalogIneligibleReason
    ) async throws {
        let sizeChecker = MockPOSCatalogSizeChecker(
            sizeToReturn: .success(POSCatalogSize(productCount: 500, variationCount: 400))
        )

        let wcPlugin: SystemPlugin? = isActive.map { active in
            SystemPlugin(
                siteID: siteID,
                plugin: "woocommerce/woocommerce.php",
                name: "WooCommerce",
                version: "10.3.0",
                versionLatest: "10.3.0",
                url: "https://woocommerce.com",
                authorName: "WooCommerce",
                authorUrl: "https://woocommerce.com",
                networkActivated: false,
                active: active
            )
        }

        let systemStatusService = MockPOSSystemStatusService(
            pluginInfoToReturn: .success(
                POSPluginAndFeatureInfo(wcPlugin: wcPlugin, featureValue: true)
            )
        )
        let service = POSLocalCatalogEligibilityService(
            catalogSizeChecker: sizeChecker,
            systemStatusService: systemStatusService,
            remoteFeatureFlagProvider: makeRemoteFeatureFlagProvider(),
            betaFeatureToggleProvider: makeBetaFeatureToggleProvider(),
            catalogSizeLimit: 1000
        )
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        let state = try await service.catalogEligibility(for: siteID)

        guard case .ineligible(let reason) = state else {
            Issue.record("Expected ineligible state")
            return
        }
        #expect(reason == expectedReason)
        #expect(sizeChecker.checkCatalogSizeCallCount == 0)
    }

    // MARK: - Skip Reason Analytics

    @Test("POSLocalCatalogIneligibleReason skipReason returns correct analytics string")
    func testSkipReasonReturnsCorrectAnalyticsString() {
        #expect(POSLocalCatalogIneligibleReason.posTabNotEligible.skipReason == "pos_not_eligible")
        #expect(POSLocalCatalogIneligibleReason.featureFlagDisabled.skipReason == "feature_flag_disabled")
        #expect(POSLocalCatalogIneligibleReason.unsupportedWooCommerceVersion(minimumVersion: "10.3.0").skipReason == "unsupported_woocommerce_version")
        #expect(POSLocalCatalogIneligibleReason.catalogSizeTooLarge(totalCount: 1500, limit: 1000).skipReason == "catalog_too_large")
        #expect(POSLocalCatalogIneligibleReason.catalogSizeCheckFailed(underlyingError: "error").skipReason == "catalog_size_check_failed")
    }

    @Test("Skip reason strings are consistent regardless of associated values")
    func testSkipReasonConsistentRegardlessOfAssociatedValues() {
        // Test that associated values don't affect the skip reason string
        let version1 = POSLocalCatalogIneligibleReason.unsupportedWooCommerceVersion(minimumVersion: "10.3.0")
        let version2 = POSLocalCatalogIneligibleReason.unsupportedWooCommerceVersion(minimumVersion: "11.0.0")
        #expect(version1.skipReason == version2.skipReason)

        let sizeTooLarge1 = POSLocalCatalogIneligibleReason.catalogSizeTooLarge(totalCount: 1500, limit: 1000)
        let sizeTooLarge2 = POSLocalCatalogIneligibleReason.catalogSizeTooLarge(totalCount: 2000, limit: 1000)
        #expect(sizeTooLarge1.skipReason == sizeTooLarge2.skipReason)

        let checkFailed1 = POSLocalCatalogIneligibleReason.catalogSizeCheckFailed(underlyingError: "error1")
        let checkFailed2 = POSLocalCatalogIneligibleReason.catalogSizeCheckFailed(underlyingError: "error2")
        #expect(checkFailed1.skipReason == checkFailed2.skipReason)
    }
}
