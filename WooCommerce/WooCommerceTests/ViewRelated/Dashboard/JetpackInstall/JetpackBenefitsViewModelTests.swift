import XCTest
@testable import WooCommerce
@testable import Yosemite

@MainActor
final class JetpackBenefitsViewModelTests: XCTestCase {
    func test_fetchJetpackUser_returns_error_for_jcp_sites() async {
        // Given
        let viewModel = JetpackBenefitsViewModel(isJetpackCPSite: true)

        // When
        let result = await viewModel.fetchJetpackUser()

        // Then
        XCTAssertEqual(result.failure as? JetpackBenefitsViewModel.FetchJetpackUserError,
                       JetpackBenefitsViewModel.FetchJetpackUserError.notSupportedForJCPSites)
    }

    func test_fetchJetpackUser_returns_result_from_jetpack_fetch_correctly() async throws {
        // Given
        let stores = MockStoresManager(sessionManager: .makeForTesting())
        let viewModel = JetpackBenefitsViewModel(isJetpackCPSite: false, stores: stores)
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
        let viewModel = JetpackBenefitsViewModel(isJetpackCPSite: false, stores: stores)
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
}
