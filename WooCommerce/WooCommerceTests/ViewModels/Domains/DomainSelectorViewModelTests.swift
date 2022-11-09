import XCTest
import Yosemite
@testable import WooCommerce

final class DomainSelectorViewModelTests: XCTestCase {
    private var stores: MockStoresManager!
    private var viewModel: DomainSelectorViewModel!

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        viewModel = .init(stores: stores, debounceDuration: 0)
    }

    override func tearDown() {
        viewModel = nil
        stores = nil
        super.tearDown()
    }

    func test_DomainAction_is_not_dispatched_when_searchTerm_is_empty() {
        // Given
        stores.whenReceivingAction(ofType: DomainAction.self) { action in
            XCTFail("Unexpected action: \(action)")
        }

        // When
        viewModel.searchTerm = ""
        viewModel.searchTerm = ""

        // Then
        XCTAssertEqual(viewModel.domains, [])
        XCTAssertTrue(stores.receivedActions.isEmpty)
    }

    func test_domain_suggestions_success_returns_domain_rows_for_free_domains() {
        // Given
        mockDomainSuggestionsSuccess(suggestions: [
            .init(name: "free.com", isFree: true),
            .init(name: "paid.com", isFree: false)
        ])

        // When
        viewModel.searchTerm = "woo"

        // Then
        waitUntil {
            self.viewModel.domains.isNotEmpty
        }
        XCTAssertEqual(viewModel.domains, ["free.com"])
    }

    func test_domain_suggestions_failure_does_not_update_domain_rows() {
        // Given
        mockDomainSuggestionsFailure(error: SampleError.first)

        // When
        viewModel.searchTerm = "woo"

        // Then
        XCTAssertEqual(viewModel.domains, [])
    }
}

private extension DomainSelectorViewModelTests {
    func mockDomainSuggestionsSuccess(suggestions: [FreeDomainSuggestion]) {
        stores.whenReceivingAction(ofType: DomainAction.self) { action in
            switch action {
            case let .loadFreeDomainSuggestions(_, completion):
                completion(.success(suggestions))
            }
        }
    }

    func mockDomainSuggestionsFailure(error: Error) {
        stores.whenReceivingAction(ofType: DomainAction.self) { action in
            switch action {
            case let .loadFreeDomainSuggestions(_, completion):
                completion(.failure(error))
            }
        }
    }
}
