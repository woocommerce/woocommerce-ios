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

    private func makeService(
        systemStatusService: MockPOSSystemStatusService,
        isLocalCatalogFeatureFlagEnabled: Bool = true,
        remoteFeatureFlagProvider: (@Sendable () async -> Bool)? = nil,
        betaFeatureToggleProvider: (@Sendable () async -> Bool)? = nil,
        syncStatusChecker: POSCatalogSyncStatusCheckerProtocol? = nil
    ) -> POSLocalCatalogEligibilityService {
        POSLocalCatalogEligibilityService(
            systemStatusService: systemStatusService,
            isLocalCatalogFeatureFlagEnabled: isLocalCatalogFeatureFlagEnabled,
            remoteFeatureFlagProvider: remoteFeatureFlagProvider ?? makeRemoteFeatureFlagProvider(),
            betaFeatureToggleProvider: betaFeatureToggleProvider ?? makeBetaFeatureToggleProvider(),
            syncStatusChecker: syncStatusChecker
        )
    }

    // MARK: - Eligibility

    @Test("Eligible when all checks pass")
    func testEligibleWhenAllChecksPass() async throws {
        let systemStatusService = MockPOSSystemStatusService()
        let service = makeService(systemStatusService: systemStatusService)
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        #expect(try await service.catalogEligibility(for: siteID) == .eligible)
    }

    @Test func test_catalogEligibility_when_version_check_fails_with_completed_full_sync_then_returns_eligible() async throws {
        // Given
        let systemStatusService = MockPOSSystemStatusService(pluginInfoToReturn: .failure(URLError(.notConnectedToInternet)))
        let service = makeService(
            systemStatusService: systemStatusService,
            syncStatusChecker: MockPOSCatalogSyncStatusChecker(hasCompletedFullSync: true)
        )
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        // When
        let state = try await service.catalogEligibility(for: siteID)

        // Then: the previously synced catalog stays usable when the version re-check fails (e.g. offline)
        #expect(state == .eligible)
    }

    @Test func test_catalogEligibility_when_version_check_fails_without_completed_full_sync_then_returns_ineligible() async throws {
        // Given
        let expectedError = NSError(domain: "test", code: 123, userInfo: nil)
        let systemStatusService = MockPOSSystemStatusService(pluginInfoToReturn: .failure(expectedError))
        let service = makeService(systemStatusService: systemStatusService)
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        // When
        let state = try await service.catalogEligibility(for: siteID)

        // Then
        guard case .ineligible(let reason) = state else {
            Issue.record("Expected ineligible state")
            return
        }
        guard case .versionCheckFailed(let errorString) = reason else {
            Issue.record("Expected versionCheckFailed reason")
            return
        }
        #expect(errorString.contains("123"))
    }

    @Test func test_updatePOSEligibility_when_value_unchanged_and_state_cached_then_skips_revalidation() async throws {
        // Given
        let systemStatusService = MockPOSSystemStatusService()
        let service = makeService(systemStatusService: systemStatusService)
        try await service.updatePOSEligibility(isEligible: true, for: siteID)
        #expect(systemStatusService.loadPluginCallCount == 1)

        // When: POS eligibility is reported again with the same value
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        // Then: the cached state is kept without re-running remote checks
        #expect(systemStatusService.loadPluginCallCount == 1)
        #expect(try await service.catalogEligibility(for: siteID) == .eligible)
    }

    @Test func test_updatePOSEligibility_when_value_unchanged_and_cached_state_is_ineligible_then_revalidates() async throws {
        // Given: the first check fails and caches an ineligible state
        let systemStatusService = MockPOSSystemStatusService(pluginInfoToReturn: .failure(NSError(domain: "test", code: 500)))
        let service = makeService(systemStatusService: systemStatusService)
        try await service.updatePOSEligibility(isEligible: true, for: siteID)
        guard case .ineligible = try await service.catalogEligibility(for: siteID) else {
            Issue.record("Expected an ineligible state to be cached")
            return
        }

        // When: the condition recovers and POS eligibility is reported again with the same value
        systemStatusService.pluginInfoToReturn = MockPOSSystemStatusService().pluginInfoToReturn
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        // Then: the cached ineligible state is re-validated instead of kept for the session
        #expect(try await service.catalogEligibility(for: siteID) == .eligible)
    }

    @Test func test_updatePOSEligibility_when_value_changes_then_revalidates() async throws {
        // Given
        let systemStatusService = MockPOSSystemStatusService()
        let service = makeService(systemStatusService: systemStatusService)
        try await service.updatePOSEligibility(isEligible: true, for: siteID)
        #expect(try await service.catalogEligibility(for: siteID) == .eligible)

        // When: POS becomes ineligible, then eligible again
        try await service.updatePOSEligibility(isEligible: false, for: siteID)
        #expect(try await service.catalogEligibility(for: siteID) == .ineligible(reason: .posTabNotEligible))
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        // Then: each change re-validates and updates the cached state
        #expect(try await service.catalogEligibility(for: siteID) == .eligible)
    }

    // MARK: - Caching

    @Test("Second call uses cached state")
    func testSecondCallUsesCachedState() async throws {
        let systemStatusService = MockPOSSystemStatusService()
        let service = makeService(systemStatusService: systemStatusService)
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        // First call
        let firstState = try await service.catalogEligibility(for: siteID)
        #expect(firstState == .eligible)
        #expect(systemStatusService.loadPluginCallCount == 1)

        // Second call should use cache
        let secondState = try await service.catalogEligibility(for: siteID)
        #expect(secondState == .eligible)
        #expect(systemStatusService.loadPluginCallCount == 1) // Should not increment
    }

    @Test("Refresh bypasses cache")
    func testRefreshBypassesCache() async throws {
        let systemStatusService = MockPOSSystemStatusService()
        let service = makeService(systemStatusService: systemStatusService)
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        // First call
        let firstState = try await service.catalogEligibility(for: siteID)
        #expect(firstState == .eligible)
        #expect(systemStatusService.loadPluginCallCount == 1)

        // Refresh should fetch again
        let refreshedState = try await service.refreshEligibilityState(for: siteID)
        #expect(refreshedState == .eligible)
        #expect(systemStatusService.loadPluginCallCount == 2) // Should increment
    }

    @Test("Refresh updates cache")
    func testRefreshUpdatesCache() async throws {
        let systemStatusService = MockPOSSystemStatusService()
        let service = makeService(systemStatusService: systemStatusService)
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        // First call caches eligible state
        _ = try await service.catalogEligibility(for: siteID)
        #expect(systemStatusService.loadPluginCallCount == 1)

        // Change the plugin info so the version check now fails eligibility
        systemStatusService.pluginInfoToReturn = .success(
            POSPluginAndFeatureInfo(
                wcPlugin: makeSystemPlugin(version: "10.4.0"),
                featureValue: true
            )
        )

        // Refresh should update cache
        let refreshedState = try await service.refreshEligibilityState(for: siteID)
        guard case .ineligible = refreshedState else {
            Issue.record("Expected ineligible after refresh")
            return
        }
        #expect(systemStatusService.loadPluginCallCount == 2)

        // Next get should return cached ineligible
        let cachedState = try await service.catalogEligibility(for: siteID)
        guard case .ineligible = cachedState else {
            Issue.record("Expected cached ineligible state")
            return
        }
        #expect(systemStatusService.loadPluginCallCount == 2) // Should not increment
    }

    // MARK: - Feature Flag

    @Test("Remote feature flag disabled returns ineligible after refresh")
    func testRemoteFeatureFlagDisabledReturnsIneligible() async throws {
        let systemStatusService = MockPOSSystemStatusService()
        let service = makeService(
            systemStatusService: systemStatusService,
            remoteFeatureFlagProvider: makeRemoteFeatureFlagProvider(returning: false)
        )
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        // First refresh might check the version (using default true before fetch completes)
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

        // Second refresh should not have checked the version (short-circuited by flag)
        // First refresh might have checked it (count could be 0 or 1)
        #expect(systemStatusService.loadPluginCallCount <= 1)
    }

    @Test("All feature flags required for eligibility")
    func testAllFeatureFlagsRequiredForEligibility() async throws {
        let systemStatusService = MockPOSSystemStatusService()

        // Test with all flags enabled - should be eligible
        let serviceWithAllEnabled = makeService(
            systemStatusService: systemStatusService,
            remoteFeatureFlagProvider: makeRemoteFeatureFlagProvider(returning: true),
            betaFeatureToggleProvider: makeBetaFeatureToggleProvider(returning: true)
        )
        try await serviceWithAllEnabled.updatePOSEligibility(isEligible: true, for: siteID)
        #expect(try await serviceWithAllEnabled.catalogEligibility(for: siteID) == .eligible)
    }

    @Test("Beta feature toggle disabled returns ineligible")
    func testBetaFeatureToggleDisabledReturnsIneligible() async throws {
        let systemStatusService = MockPOSSystemStatusService()
        let service = makeService(
            systemStatusService: systemStatusService,
            betaFeatureToggleProvider: makeBetaFeatureToggleProvider(returning: false)
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
    }

    // MARK: - POS Eligibility

    @Test("POS not eligible returns ineligible")
    func testPOSNotEligibleReturnsIneligible() async throws {
        let systemStatusService = MockPOSSystemStatusService()
        let service = makeService(systemStatusService: systemStatusService)

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

        // Should not have checked the WooCommerce version
        #expect(systemStatusService.loadPluginCallCount == 0)
    }

    // MARK: - WooCommerce Version Checking

    @Test("WooCommerce version eligibility",
          arguments: [
            ("10.2.0", true, false),        // Below minimum
            ("10.4.0", true, false),        // Below minimum
            ("10.5.0", true, true),         // At minimum
            ("11.0.0", true, true),         // Above minimum
          ])
    func testWooCommerceVersionEligibility(
        version: String,
        isActive: Bool,
        expectEligible: Bool
    ) async throws {
        let systemStatusService = MockPOSSystemStatusService(
            pluginInfoToReturn: .success(
                POSPluginAndFeatureInfo(
                    wcPlugin: makeSystemPlugin(version: version, active: isActive),
                    featureValue: true
                )
            )
        )
        let service = makeService(systemStatusService: systemStatusService)
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
            #expect(minimumVersion == "10.5.0")
        }
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
        let wcPlugin: SystemPlugin? = isActive.map { active in
            makeSystemPlugin(version: "10.5.0", active: active)
        }

        let systemStatusService = MockPOSSystemStatusService(
            pluginInfoToReturn: .success(
                POSPluginAndFeatureInfo(wcPlugin: wcPlugin, featureValue: true)
            )
        )
        let service = makeService(systemStatusService: systemStatusService)
        try await service.updatePOSEligibility(isEligible: true, for: siteID)

        let state = try await service.catalogEligibility(for: siteID)

        guard case .ineligible(let reason) = state else {
            Issue.record("Expected ineligible state")
            return
        }
        #expect(reason == expectedReason)
    }

    // MARK: - Skip Reason Analytics

    @Test("POSLocalCatalogIneligibleReason skipReason returns correct analytics string")
    func testSkipReasonReturnsCorrectAnalyticsString() {
        #expect(POSLocalCatalogIneligibleReason.posTabNotEligible.skipReason == "pos_not_eligible")
        #expect(POSLocalCatalogIneligibleReason.featureFlagDisabled.skipReason == "feature_flag_disabled")
        #expect(POSLocalCatalogIneligibleReason.unsupportedWooCommerceVersion(minimumVersion: "10.5.0").skipReason == "unsupported_woocommerce_version")
        #expect(POSLocalCatalogIneligibleReason.versionCheckFailed(underlyingError: "error").skipReason == "version_check_failed")
    }

    @Test("Skip reason strings are consistent regardless of associated values")
    func testSkipReasonConsistentRegardlessOfAssociatedValues() {
        // Test that associated values don't affect the skip reason string
        let version1 = POSLocalCatalogIneligibleReason.unsupportedWooCommerceVersion(minimumVersion: "10.5.0")
        let version2 = POSLocalCatalogIneligibleReason.unsupportedWooCommerceVersion(minimumVersion: "11.0.0")
        #expect(version1.skipReason == version2.skipReason)

        let checkFailed1 = POSLocalCatalogIneligibleReason.versionCheckFailed(underlyingError: "error1")
        let checkFailed2 = POSLocalCatalogIneligibleReason.versionCheckFailed(underlyingError: "error2")
        #expect(checkFailed1.skipReason == checkFailed2.skipReason)
    }

    // MARK: - Helpers

    private func makeSystemPlugin(version: String, active: Bool = true) -> SystemPlugin {
        SystemPlugin(
            siteID: siteID,
            plugin: "woocommerce/woocommerce.php",
            name: "WooCommerce",
            version: version,
            versionLatest: "11.0.0",
            url: "https://woocommerce.com",
            authorName: "WooCommerce",
            authorUrl: "https://woocommerce.com",
            networkActivated: false,
            active: active
        )
    }
}

/// Mock sync status checker for eligibility tolerance checks.
private struct MockPOSCatalogSyncStatusChecker: POSCatalogSyncStatusCheckerProtocol {
    let hasCompletedFullSync: Bool

    func hasCompletedFullSync(for siteID: Int64) async -> Bool {
        hasCompletedFullSync
    }
}
