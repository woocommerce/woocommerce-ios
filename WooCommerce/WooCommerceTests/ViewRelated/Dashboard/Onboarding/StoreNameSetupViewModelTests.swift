import XCTest
@testable import Yosemite
@testable import WooCommerce

final class StoreNameSetupViewModelTests: XCTestCase {

    private var stores: MockStoresManager!

    override func setUp() {
        stores = MockStoresManager(sessionManager: .makeForTesting())
    }

    override func tearDown() {
        stores = nil
    }

    func test_shouldEnableSaving_returns_false_if_store_name_is_empty() {
        // Given
        let viewModel = StoreNameSetupViewModel(siteID: 123, name: "Test", onNameSaved: {})

        // When
        viewModel.name = ""

        // Then
        XCTAssertFalse(viewModel.shouldEnableSaving)
    }

    func test_shouldEnableSaving_returns_false_if_store_name_is_not_updated() {
        // Given
        let viewModel = StoreNameSetupViewModel(siteID: 123, name: "Test", onNameSaved: {})

        // Then
        XCTAssertFalse(viewModel.shouldEnableSaving)
    }

    func test_shouldEnableSaving_returns_true_if_store_name_is_updated() {
        // Given
        let viewModel = StoreNameSetupViewModel(siteID: 123, name: "Test", onNameSaved: {})

        // When
        viewModel.name = "Kitty"

        // Then
        XCTAssertTrue(viewModel.shouldEnableSaving)
    }

    func test_isSavingInProgress_returns_true_upon_saving_name() {
        // Given
        let viewModel = StoreNameSetupViewModel(siteID: 123, name: "Test", stores: stores, onNameSaved: {})
        XCTAssertFalse(viewModel.isSavingInProgress)

        // When
        viewModel.name = "Miffy"
        viewModel.saveName()

        // Then
        XCTAssertTrue(viewModel.isSavingInProgress)
    }

    func test_isSavingInProgress_returns_false_upon_saving_name_completes() {
        // Given
        let viewModel = StoreNameSetupViewModel(siteID: 123, name: "Test", stores: stores, onNameSaved: {})
        XCTAssertFalse(viewModel.isSavingInProgress)
        mockStoreNameUpdate(result: .success(Site.fake()))

        // When
        viewModel.name = "Miffy"
        viewModel.saveName()

        // Then
        XCTAssertFalse(viewModel.isSavingInProgress)
    }

    func test_onNameSaved_is_triggered_upon_saving_store_name_success() {
        // Given
        var onNameSavedTriggered = false
        let viewModel = StoreNameSetupViewModel(siteID: 123, name: "Test", stores: stores, onNameSaved: {
            onNameSavedTriggered = true
        })
        mockStoreNameUpdate(result: .success(Site.fake()))

        // When
        viewModel.name = "Miffy"
        viewModel.saveName()

        // Then
        XCTAssertTrue(onNameSavedTriggered)
    }

    func test_errorMessage_is_updated_upon_saving_store_name_failure() {
        let viewModel = StoreNameSetupViewModel(siteID: 123, name: "Test", stores: stores, onNameSaved: {})
        mockStoreNameUpdate(result: .failure(NSError(domain: "Test", code: 1)))
        XCTAssertNil(viewModel.errorMessage)

        // When
        viewModel.name = "Miffy"
        viewModel.saveName()

        // Then
        XCTAssertNotNil(viewModel.errorMessage)
    }
}

private extension StoreNameSetupViewModelTests {
    func mockStoreNameUpdate(result: Result<Site, Error>) {
        stores.whenReceivingAction(ofType: SiteAction.self) { action in
            switch action {
            case let .updateSiteTitle(_, _, completion):
                completion(result)
            default:
                break
            }
        }
    }
}
