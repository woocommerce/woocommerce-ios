import XCTest
import Yosemite
@testable import WooCommerce

final class SiteConnectionTypeTests: XCTestCase {

    // MARK: - init(site:) tests

    func test_init_with_nil_site_returns_unknown() {
        // Given
        let site: Site? = nil

        // When
        let siteConnectionType = SiteConnectionType(site: site)

        // Then
        XCTAssertEqual(siteConnectionType, .unknown)
    }

    func test_init_with_non_jetpack_connected_site_returns_nonJetpack() {
        // Given
        let site = Site.fake().copy(isJetpackThePluginInstalled: false, isJetpackConnected: false)

        // When
        let siteConnectionType = SiteConnectionType(site: site)

        // Then
        XCTAssertEqual(siteConnectionType, .nonJetpack)
    }

    func test_init_with_jetpack_connected_but_plugin_not_installed_returns_jetpackConnectionPackage() {
        // Given
        // isJetpackCPConnected is computed as: isJetpackConnected && !isJetpackThePluginInstalled
        let site = Site.fake().copy(isJetpackThePluginInstalled: false, isJetpackConnected: true)

        // When
        let siteConnectionType = SiteConnectionType(site: site)

        // Then
        XCTAssertEqual(siteConnectionType, .jetpackConnectionPackage)
    }

    func test_init_with_jetpack_connected_and_plugin_installed_returns_fullJetpack() {
        // Given
        let site = Site.fake().copy(isJetpackThePluginInstalled: true, isJetpackConnected: true)

        // When
        let siteConnectionType = SiteConnectionType(site: site)

        // Then
        XCTAssertEqual(siteConnectionType, .fullJetpack)
    }

    func test_supportsJetpackVisitorStats_returns_true_for_self_hosted_full_jetpack_site() {
        // Given
        let site = Site.fake().copy(isJetpackThePluginInstalled: true,
                                    isJetpackConnected: true,
                                    isWordPressComStore: false)

        // Then
        XCTAssertTrue(site.supportsJetpackVisitorStats)
    }

    func test_supportsJetpackVisitorStats_returns_false_for_wpcom_site() {
        // Given
        let site = Site.fake().copy(isJetpackThePluginInstalled: true,
                                    isJetpackConnected: true,
                                    isWordPressComStore: true)

        // Then
        XCTAssertFalse(site.supportsJetpackVisitorStats)
    }

    func test_supportsJetpackVisitorStats_returns_false_for_jetpack_connection_package_site() {
        // Given
        let site = Site.fake().copy(isJetpackThePluginInstalled: false,
                                    isJetpackConnected: true,
                                    isWordPressComStore: false)

        // Then
        XCTAssertFalse(site.supportsJetpackVisitorStats)
    }

    // MARK: - analyticsValue tests

    func test_analyticsValue_for_nonJetpack_returns_correct_string() {
        XCTAssertEqual(SiteConnectionType.nonJetpack.analyticsValue, "non_jetpack")
    }

    func test_analyticsValue_for_jetpackConnectionPackage_returns_correct_string() {
        XCTAssertEqual(SiteConnectionType.jetpackConnectionPackage.analyticsValue, "jetpack_connection_package")
    }

    func test_analyticsValue_for_fullJetpack_returns_correct_string() {
        XCTAssertEqual(SiteConnectionType.fullJetpack.analyticsValue, "full_jetpack")
    }

    func test_analyticsValue_for_unknown_returns_correct_string() {
        XCTAssertEqual(SiteConnectionType.unknown.analyticsValue, "unknown")
    }
}
