import XCTest

import protocol Storage.StorageType
import protocol Storage.StorageManagerType

@testable import WooCommerce

final class SettingsViewModelTests: XCTestCase {

    /// Mock Storage: InMemory
    ///
    private var storageManager: StorageManagerType!

    /// Mock Stores
    ///
    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
    }

    override func tearDown() {
        storageManager = nil
        stores = nil
        super.tearDown()
    }

    func test_sections_is_not_empty_after_view_did_load() {
        // Given
        let viewModel = SettingsViewModel(stores: stores, storageManager: storageManager)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertTrue(viewModel.sections.count > 0)
    }

    func test_sections_contain_install_jetpack_row_when_JCP_support_feature_flag_is_on() {
        // Given
        let featureFlagService = MockFeatureFlagService(isJetpackConnectionPackageSupportOn: true)
        let viewModel = SettingsViewModel(
            stores: stores,
            storageManager: storageManager,
            featureFlagService: featureFlagService)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertTrue(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.installJetpack) })
    }

    func test_sections_does_not_contain_install_jetpack_row_when_JCP_support_feature_flag_is_off() {
        // Given
        let featureFlagService = MockFeatureFlagService(isJetpackConnectionPackageSupportOn: false)
        let viewModel = SettingsViewModel(
            stores: stores,
            storageManager: storageManager,
            featureFlagService: featureFlagService)

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertFalse(viewModel.sections.contains { $0.rows.contains(SettingsViewController.Row.installJetpack) })
    }

    func test_refresh_view_content_method_is_invoked_after_view_did_load() {
        // Given
        let viewModel = SettingsViewModel(stores: stores, storageManager: storageManager)
        let presenter = MockSettingsPresenter()
        viewModel.presenter = presenter

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertTrue(presenter.refreshViewContentCalled)
    }

    func test_refresh_view_content_method_is_invoked_after_dismissing_store_picker() {
        // Given
        let viewModel = SettingsViewModel(stores: stores, storageManager: storageManager)
        let presenter = MockSettingsPresenter()
        viewModel.presenter = presenter

        // When
        viewModel.onViewDidLoad()

        // Then
        XCTAssertTrue(presenter.refreshViewContentCalled)

        // Reset
        presenter.refreshViewContentCalled = false

        // When
        viewModel.onStorePickerDismiss()

        // Then
        XCTAssertTrue(presenter.refreshViewContentCalled)
    }
}

private final class MockSettingsPresenter: SettingsViewPresenter {

    var refreshViewContentCalled = false

    func refreshViewContent() {
        refreshViewContentCalled = true
    }
}
