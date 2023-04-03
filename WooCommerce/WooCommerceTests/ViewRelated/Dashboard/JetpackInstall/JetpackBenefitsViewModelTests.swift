import XCTest
@testable import WooCommerce
@testable import Yosemite

@MainActor
final class JetpackBenefitsViewModelTests: XCTestCase {
    private let siteURL = "https://example.com"

    func test_shouldShowWebViewForJetpackInstall_is_false_for_jcp_sites() {
        // Given
        let viewModel = JetpackBenefitsViewModel(siteURL: siteURL, isJetpackCPSite: true)

        // Then
        XCTAssertFalse(viewModel.shouldShowWebViewForJetpackInstall)
    }

    func test_shouldShowWebViewForJetpackInstall_is_false_for_non_jp_sites_when_jetpack_setup_is_enabled() {
        // Given
        let featureFlagService = MockFeatureFlagService(jetpackSetupWithApplicationPassword: true)
        let viewModel = JetpackBenefitsViewModel(siteURL: siteURL, isJetpackCPSite: false, featureFlagService: featureFlagService)

        // Then
        XCTAssertFalse(viewModel.shouldShowWebViewForJetpackInstall)
    }

    func test_shouldShowWebViewForJetpackInstall_is_true_for_non_jp_sites_when_jetpack_setup_is_disabled() {
        // Given
        let featureFlagService = MockFeatureFlagService(jetpackSetupWithApplicationPassword: false)
        let viewModel = JetpackBenefitsViewModel(siteURL: siteURL, isJetpackCPSite: false, featureFlagService: featureFlagService)

        // Then
        XCTAssertTrue(viewModel.shouldShowWebViewForJetpackInstall)
    }

    func test_wpAdminInstallURL_is_correct() {
        // Given
        let viewModel = JetpackBenefitsViewModel(siteURL: siteURL, isJetpackCPSite: false)

        // Then
        XCTAssertEqual(viewModel.wpAdminInstallURL?.absoluteString, "https://wordpress.com/jetpack/connect?url=\(siteURL)&from=mobile")
    }
}
