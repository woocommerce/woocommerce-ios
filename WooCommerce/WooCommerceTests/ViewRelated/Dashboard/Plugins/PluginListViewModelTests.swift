import XCTest
@testable import Storage
@testable import WooCommerce
@testable import Yosemite

class PluginListViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 134

    /// Mock Storage: InMemory
    ///
    private var storageManager: StorageManagerType!

    /// View storage for tests
    ///
    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    func test_section_and_row_details_are_correct_after_activation() {
        // Given
        let activePlugin = SitePlugin.fake().copy(
            siteID: sampleSiteID,
            status: .active,
            name: "BBB",
            descriptionRaw: "Lorem ipsum <strong>random HTML content</strong>"
        )
        insert(activePlugin)

        let inactivePlugin1 = SitePlugin.fake().copy(siteID: sampleSiteID, status: .inactive, name: "CCC")
        insert(inactivePlugin1)

        let inactivePlugin2 = SitePlugin.fake().copy(siteID: sampleSiteID, status: .inactive, name: "AAA")
        insert(inactivePlugin2)

        let viewModel = PluginListViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.activate()

        // Then
        XCTAssertEqual(viewModel.numberOfSections, 2)
        XCTAssertEqual(viewModel.titleForSection(at: 0), "Active Plugins")
        XCTAssertEqual(viewModel.titleForSection(at: 1), "Inactive Plugins")
        XCTAssertEqual(viewModel.numberOfRows(inSection: 0), 1)
        XCTAssertEqual(viewModel.numberOfRows(inSection: 1), 2)
        XCTAssertEqual(viewModel.cellModelForRow(at: IndexPath(row: 0, section: 0)).name, activePlugin.name)
        XCTAssertEqual(viewModel.cellModelForRow(at: IndexPath(row: 0, section: 0)).description, "Lorem ipsum random HTML content")
        XCTAssertEqual(viewModel.cellModelForRow(at: IndexPath(row: 0, section: 1)).name, inactivePlugin2.name)
        XCTAssertEqual(viewModel.cellModelForRow(at: IndexPath(row: 1, section: 1)).name, inactivePlugin1.name)
    }

    func test_resyncPlugins_dispatches_correct_action() {
        // Given
        let storesManager = MockPluginStoresManager(shouldSucceed: true)
        let viewModel = PluginListViewModel(siteID: sampleSiteID, storesManager: storesManager)

        // When
        viewModel.resyncPlugins {}

        // Then
        XCTAssertTrue(storesManager.invokedSynchronizePlugins)
        XCTAssertEqual(storesManager.invokedSynchronizePluginsWithSiteID, sampleSiteID)
    }

    func test_resyncPlugins_updates_pluginListState_to_results_when_synchronization_succeeds() {
        // Given
        let storesManager = MockPluginStoresManager(shouldSucceed: true)
        let viewModel = PluginListViewModel(siteID: sampleSiteID, storesManager: storesManager)

        // When
        viewModel.resyncPlugins {}

        // Then
        XCTAssertEqual(viewModel.pluginListState, .results)
    }

    func test_resyncPlugins_updates_pluginListState_to_error_when_synchronization_fails() {
        // Given
        let storesManager = MockPluginStoresManager(shouldSucceed: false)
        let viewModel = PluginListViewModel(siteID: sampleSiteID, storesManager: storesManager)

        // When
        viewModel.resyncPlugins {}

        // Then
        XCTAssertEqual(viewModel.pluginListState, .error)
    }
}

private extension PluginListViewModelTests {
    func insert(_ readOnlyPlugin: Yosemite.SitePlugin) {
        let plugin = storage.insertNewObject(ofType: StorageSitePlugin.self)
        plugin.update(with: readOnlyPlugin)
    }
}

final class MockPluginStoresManager: DefaultStoresManager {
    var invokedSynchronizePlugins = false
    var invokedSynchronizePluginsWithSiteID: Int64 = 0

    private var shouldSucceed = false

    enum MockPluginError: Error {
        case mockError
    }

    init(shouldSucceed: Bool) {
        self.shouldSucceed = shouldSucceed
        let sessionManager = SessionManager.testingInstance
        sessionManager.setStoreId(134)
        super.init(sessionManager: sessionManager)
    }

    // MARK: - Overridden Methods
    override func dispatch(_ action: Action) {
        if let sitePluginAction = action as? SitePluginAction {
            onPluginAction(sitePluginAction)
        }
    }

    private func onPluginAction(_ action: SitePluginAction) {
        switch action {
        case .synchronizeSitePlugins(let siteID, let onCompletion):
            invokedSynchronizePlugins = true
            invokedSynchronizePluginsWithSiteID = siteID
            if shouldSucceed {
                onCompletion(.success(()))
            } else {
                onCompletion(.failure(MockPluginError.mockError))
            }
        }
    }
}
