import XCTest
@testable import WooCommerce
@testable import Yosemite

@MainActor
final class JetpackBenefitsViewModelTests: XCTestCase {
    private let siteURL = "https://example.com"

    func test_fetchJetpackUser_returns_error_for_jcp_sites() async {
        // Given
        let viewModel = JetpackBenefitsViewModel(siteURL: siteURL, isJetpackCPSite: true)

        // When
        let result = await viewModel.fetchJetpackUser()

        // Then
        XCTAssertEqual(result.failure as? JetpackBenefitsViewModel.FetchJetpackUserError,
                       JetpackBenefitsViewModel.FetchJetpackUserError.notSupportedForJCPSites)
    }

    func test_fetchJetpackUser_returns_result_from_jetpack_fetch_correctly() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackBenefitsViewModel(siteURL: siteURL, isJetpackCPSite: false, stores: stores)
        let testUser = JetpackUser.fake().copy(username: "test")

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackUser(let completion):
                completion(.success(testUser))
            default:
                break
            }
        }

        // When
        let result = await viewModel.fetchJetpackUser()

        //  Then
        XCTAssertEqual(try result.get().username, testUser.username)
    }

    func test_fetchJetpackUser_relays_error_from_jetpack_fetch() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackBenefitsViewModel(siteURL: siteURL, isJetpackCPSite: false, stores: stores)
        let testError = NSError(domain: "Test", code: 404)

        stores.whenReceivingAction(ofType: JetpackConnectionAction.self) { action in
            switch action {
            case .fetchJetpackUser(let completion):
                completion(.failure(testError))
            default:
                break
            }
        }

        // When
        let result = await viewModel.fetchJetpackUser()

        //  Then
        XCTAssertEqual(result.failure as? NSError, testError)
    }

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
