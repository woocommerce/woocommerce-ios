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

    func test_isSavingInProgress_returns_false_upon_saving_name_completes() async {
        // Given
        let viewModel = StoreNameSetupViewModel(siteID: 123, name: "Test", stores: stores, onNameSaved: {})
        XCTAssertFalse(viewModel.isSavingInProgress)
        mockStoreNameUpdate(result: .success(Void()))

        // When
        viewModel.name = "Miffy"
        await viewModel.saveName()

        // Then
        XCTAssertFalse(viewModel.isSavingInProgress)
    }

    @MainActor
    func test_onNameSaved_is_triggered_upon_saving_store_name_success() async {
        // Given
        var onNameSavedTriggered = false
        let viewModel = StoreNameSetupViewModel(siteID: 123, name: "Test", stores: stores, onNameSaved: {
            onNameSavedTriggered = true
        })
        mockStoreNameUpdate(result: .success(Void()))

        // When
        viewModel.name = "Miffy"
        await viewModel.saveName()

        // Then
        XCTAssertTrue(onNameSavedTriggered)
    }

    @MainActor
    func test_errorMessage_is_updated_upon_saving_store_name_failure() async {
        // Given
        let viewModel = StoreNameSetupViewModel(siteID: 123, name: "Test", stores: stores, onNameSaved: {})
        mockStoreNameUpdate(result: .failure(NSError(domain: "Test", code: 1)))
        XCTAssertNil(viewModel.errorMessage)

        // When
        viewModel.name = "Miffy"
        await viewModel.saveName()

        // Then
        XCTAssertNotNil(viewModel.errorMessage)
    }

    @MainActor
    func test_default_store_name_is_updated_upon_saving_store_name_completes() async {
        // Given
        let originalSite = Site.fake().copy(siteID: 123, name: "Test")
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: originalSite))
        let viewModel = StoreNameSetupViewModel(siteID: originalSite.siteID, name: originalSite.name, stores: stores, onNameSaved: {})
        mockStoreNameUpdate(result: .success(Void()))

        // When
        viewModel.name = "Miffy"
        await viewModel.saveName()

        // Then
        XCTAssertEqual(stores.sessionManager.defaultSite?.name, "Miffy")
    }
}

private extension StoreNameSetupViewModelTests {
    func mockStoreNameUpdate(result: Result<Void, Error>) {
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
