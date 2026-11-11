import Combine
import Testing
import UIKit

@testable import WooCommerce

@MainActor
final class SearchViewControllerTests {
    private var window: UIWindow?

    @Test
    func test_query_changes_when_initial_value_is_reassigned_then_ignores_duplicate_but_emits_typing_and_clear() {
        // Given
        let model = SearchViewControllerSearchFieldModel()
        var receivedQueries: [String] = []
        let subscription = model.queryChanges.sink { query in
            receivedQueries.append(query)
        }

        // When
        model.query = ""
        model.query = "shirt"
        model.query = "shirt"
        model.query = ""

        // Then
        #expect(receivedQueries == ["shirt", ""])
        withExtendedLifetime(subscription) {}
    }

    @Test
    func test_view_when_store_design_system_is_enabled_then_hosts_store_search_field_and_hides_legacy_search_bar() throws {
        // Given
        let sut = makeSUT(usesStoreDesignSystem: true)

        // When
        sut.loadViewIfNeeded()

        // Then
        let searchBar = try #require(sut.view.firstSubview(ofType: UISearchBar.self))
        #expect(searchBar.isHidden)
        #expect(storeSearchFieldHostingController(in: sut) != nil)
    }

    @Test
    func test_view_when_store_design_system_is_disabled_then_keeps_legacy_search_bar() throws {
        // Given
        let sut = makeSUT(usesStoreDesignSystem: false)

        // When
        sut.loadViewIfNeeded()

        // Then
        let searchBar = try #require(sut.view.firstSubview(ofType: UISearchBar.self))
        #expect(searchBar.isHidden == false)
        #expect(storeSearchFieldHostingController(in: sut) == nil)
    }

    @Test
    func test_cancel_action_when_store_design_system_is_enabled_then_uses_command_cancel() throws {
        // Given
        var cancelCallCount = 0
        let sut = makeSUT(usesStoreDesignSystem: true) {
            cancelCallCount += 1
        }
        sut.loadViewIfNeeded()
        let hostingController = try #require(storeSearchFieldHostingController(in: sut))

        // When
        hostingController.rootView.onAction()

        // Then
        #expect(cancelCallCount == 1)
    }

    @Test
    func test_view_did_appear_when_command_requests_initial_focus_then_focuses_store_search_field() async throws {
        // Given
        let sut = makeSUT(usesStoreDesignSystem: true)
        sut.loadViewIfNeeded()
        let hostingController = try #require(storeSearchFieldHostingController(in: sut))
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = sut

        // When
        window?.makeKeyAndVisible()
        sut.view.frame = window?.bounds ?? UIScreen.main.bounds
        sut.view.layoutIfNeeded()
        hostingController.view.layoutIfNeeded()
        try await Task.sleep(for: .milliseconds(100))
        hostingController.view.layoutIfNeeded()

        // Then
        let textField = try #require(hostingController.view.firstSubview(ofType: UITextField.self))
        #expect(textField.isFirstResponder)
        window?.isHidden = true
        window = nil
    }
}

private extension SearchViewControllerTests {
    typealias SUT = SearchViewController<ProductsTabProductTableViewCell, ProductSearchUICommand>
    typealias SearchFieldHostingController = SelfSizingHostingController<SearchViewControllerSearchField>

    func makeSUT(usesStoreDesignSystem: Bool, onCancel: @escaping () -> Void = {}) -> SUT {
        let featureFlagService = MockFeatureFlagService()
        featureFlagService.isFeatureFlagEnabledReturnValue[.storeDesignSystem] = usesStoreDesignSystem
        let command = ProductSearchUICommand(siteID: 123,
                                             onProductSelection: { _ in },
                                             onCancel: onCancel)
        return SearchViewController(storeID: 123,
                                    command: command,
                                    cellType: ProductsTabProductTableViewCell.self,
                                    cellSeparator: .none,
                                    featureFlagService: featureFlagService)
    }

    func storeSearchFieldHostingController(in sut: SUT) -> SearchFieldHostingController? {
        sut.children.compactMap { $0 as? SearchFieldHostingController }.first
    }
}
