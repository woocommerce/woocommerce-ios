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

    func test_numberOfSections_is_correct_when_there_are_only_active_plugins() {
        // Given
        let activePlugin = SitePlugin.fake().copy(siteID: sampleSiteID, status: .active, name: "BBB")
        insert(activePlugin)

        let viewModel = PluginListViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.observePlugins {}

        // Then
        XCTAssertEqual(viewModel.numberOfSections, 1)
    }

    func test_numberOfSections_is_correct_when_there_are_only_inactive_plugins() {
        // Given
        let inactivePlugin = SitePlugin.fake().copy(siteID: sampleSiteID, status: .inactive, name: "CCC")
        insert(inactivePlugin)

        let viewModel = PluginListViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.observePlugins {}

        // Then
        XCTAssertEqual(viewModel.numberOfSections, 1)
    }

    func test_numberOfSections_is_correct_when_there_are_active_inactive_and_networkActive_plugins() {
        // Given
        let activePlugin = SitePlugin.fake().copy(siteID: sampleSiteID, status: .active, name: "BBB")
        insert(activePlugin)

        let inactivePlugin = SitePlugin.fake().copy(siteID: sampleSiteID, status: .inactive, name: "CCC")
        insert(inactivePlugin)

        let networkActivePlugin = SitePlugin.fake().copy(siteID: sampleSiteID, status: .networkActive, name: "CCC")
        insert(networkActivePlugin)

        let viewModel = PluginListViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.observePlugins {}

        // Then
        XCTAssertEqual(viewModel.numberOfSections, 3)
    }

    func test_titleForSection_are_correct() {
        // Given
        let activePlugin = SitePlugin.fake().copy(siteID: sampleSiteID, status: .active, name: "BBB")
        insert(activePlugin)

        let inactivePlugin = SitePlugin.fake().copy(siteID: sampleSiteID, status: .inactive, name: "CCC")
        insert(inactivePlugin)

        let networkActivePlugin = SitePlugin.fake().copy(siteID: sampleSiteID, status: .networkActive, name: "CCC")
        insert(networkActivePlugin)

        let viewModel = PluginListViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.observePlugins {}

        // Then
        XCTAssertEqual(viewModel.titleForSection(at: 0), "Active Plugins")
        XCTAssertEqual(viewModel.titleForSection(at: 1), "Inactive Plugins")
        XCTAssertEqual(viewModel.titleForSection(at: 2), "Network Active Plugins")
    }

    func test_numberOfRows_is_correct() {
        // Given
        let activePlugin = SitePlugin.fake().copy(siteID: sampleSiteID, status: .active, name: "BBB")
        insert(activePlugin)

        let inactivePlugin1 = SitePlugin.fake().copy(siteID: sampleSiteID, status: .inactive, name: "CCC")
        insert(inactivePlugin1)

        let inactivePlugin2 = SitePlugin.fake().copy(siteID: sampleSiteID, status: .inactive, name: "AAA")
        insert(inactivePlugin2)

        let viewModel = PluginListViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.observePlugins {}

        // Then
        XCTAssertEqual(viewModel.numberOfRows(inSection: 0), 1)
        XCTAssertEqual(viewModel.numberOfRows(inSection: 1), 2)
    }

    func test_cellModel_details_are_correct() {
        // Given
        let activePlugin = SitePlugin.fake().copy(
            siteID: sampleSiteID,
            status: .active,
            name: "BBB",
            descriptionRaw: "Lorem ipsum random HTML content"
        )
        insert(activePlugin)

        let viewModel = PluginListViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.observePlugins {}

        // Then
        XCTAssertEqual(viewModel.cellModelForRow(at: IndexPath(row: 0, section: 0)).name, activePlugin.name)
        XCTAssertEqual(viewModel.cellModelForRow(at: IndexPath(row: 0, section: 0)).description, activePlugin.descriptionRaw)
    }

    func test_plugins_are_sorted_by_name_in_a_section() {
        // Given
        let inactivePlugin1 = SitePlugin.fake().copy(siteID: sampleSiteID, status: .inactive, name: "CCC")
        insert(inactivePlugin1)

        let inactivePlugin2 = SitePlugin.fake().copy(siteID: sampleSiteID, status: .inactive, name: "AAA")
        insert(inactivePlugin2)

        let viewModel = PluginListViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.observePlugins {}

        // Then
        XCTAssertEqual(viewModel.cellModelForRow(at: IndexPath(row: 0, section: 0)).name, inactivePlugin2.name)
        XCTAssertEqual(viewModel.cellModelForRow(at: IndexPath(row: 1, section: 0)).name, inactivePlugin1.name)
    }

    func test_cellModel_html_tags_and_entites_are_removed() {
        // Given
        let activePlugin = SitePlugin.fake().copy(
            siteID: sampleSiteID,
            status: .active,
            name: "BBB &amp; CCC",
            descriptionRaw: "Lorem ipsum random <strong>HTML</strong> <i>content</i>"
        )
        insert(activePlugin)

        let viewModel = PluginListViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.observePlugins {}

        // Then
        XCTAssertEqual(viewModel.cellModelForRow(at: IndexPath(row: 0, section: 0)).name, "BBB & CCC")
        XCTAssertEqual(viewModel.cellModelForRow(at: IndexPath(row: 0, section: 0)).description, "Lorem ipsum random HTML content")
    }

    func test_section_info_is_correct_after_plugin_status_is_updated() {
        // Given
        let activePlugin = SitePlugin.fake().copy(siteID: sampleSiteID, status: .active, name: "AAA")
        insert(activePlugin)

        let viewModel = PluginListViewModel(siteID: sampleSiteID, storageManager: storageManager)
        XCTAssertEqual(viewModel.numberOfSections, 1)
        XCTAssertEqual(viewModel.titleForSection(at: 0), "Active Plugins")

        // When
        let pluginsChanged: Bool = waitFor { promise in
            viewModel.observePlugins {
                promise(true)
            }
            self.updateStorage(with: activePlugin.copy(status: .inactive))
        }

        // Then
        XCTAssertTrue(pluginsChanged)
        XCTAssertEqual(viewModel.numberOfSections, 1)
        XCTAssertEqual(viewModel.titleForSection(at: 0), "Inactive Plugins")
    }

    func test_cellModel_is_correct_after_plugin_is_deleted() {
        // Given
        let plugin1 = SitePlugin.fake().copy(siteID: sampleSiteID, status: .active, name: "AAA")
        insert(plugin1)

        let plugin2 = SitePlugin.fake().copy(siteID: sampleSiteID, status: .active, name: "BBB")
        insert(plugin2)

        let viewModel = PluginListViewModel(siteID: sampleSiteID, storageManager: storageManager)
        XCTAssertEqual(viewModel.numberOfRows(inSection: 0), 2)

        // When
        let pluginsChanged: Bool = waitFor { promise in
            viewModel.observePlugins {
                promise(true)
            }
            self.storage.deleteStalePlugins(siteID: self.sampleSiteID, installedPluginNames: [plugin2.name])
        }

        // Then
        XCTAssertTrue(pluginsChanged)
        XCTAssertEqual(viewModel.numberOfRows(inSection: 0), 1)
        XCTAssertEqual(viewModel.cellModelForRow(at: IndexPath(row: 0, section: 0)).name, plugin2.name)
    }

    func test_syncPlugins_dispatches_synchronizeSitePlugins_action_with_correct_siteID() {
        // Given
        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        var triggeredSiteID: Int64?
        storesManager.whenReceivingAction(ofType: SitePluginAction.self) { action in
            switch action {
            case .synchronizeSitePlugins(let siteID, _):
                triggeredSiteID = siteID
            default:
                break
            }
        }
        let viewModel = PluginListViewModel(siteID: sampleSiteID, storesManager: storesManager)

        // When
        viewModel.syncPlugins { _ in }

        // Then
        XCTAssertEqual(triggeredSiteID, sampleSiteID)
    }

    func test_syncPlugins_returns_success_when_synchronizeSitePlugins_action_completes_successfully() {
        // Given
        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        storesManager.whenReceivingAction(ofType: SitePluginAction.self) { action in
            switch action {
            case .synchronizeSitePlugins(_, let completion):
                completion(.success(()))
            default:
                break
            }
        }
        let viewModel = PluginListViewModel(siteID: sampleSiteID, storesManager: storesManager)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            viewModel.syncPlugins { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_syncPlugins_returns_error_when_synchronizeSitePlugins_action_fails() {
        // Given
        let storesManager = MockStoresManager(sessionManager: .testingInstance)
        storesManager.whenReceivingAction(ofType: SitePluginAction.self) { action in
            switch action {
            case .synchronizeSitePlugins(_, let completion):
                completion(.failure(MockPluginError.mockError))
            default:
                break
            }
        }
        let viewModel = PluginListViewModel(siteID: sampleSiteID, storesManager: storesManager)

        // When
        let result: Result<Void, Error> = waitFor { promise in
            viewModel.syncPlugins { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }
}

// MARK: - Storage helpers
//
private extension PluginListViewModelTests {
    func insert(_ readOnlyPlugin: Yosemite.SitePlugin) {
        let plugin = storage.insertNewObject(ofType: StorageSitePlugin.self)
        plugin.update(with: readOnlyPlugin)
        storage.saveIfNeeded()
    }

    func updateStorage(with readOnlyPlugin: Yosemite.SitePlugin) {
        guard let plugin = storage.loadPlugin(siteID: readOnlyPlugin.siteID, name: readOnlyPlugin.name) else {
            return
        }
        plugin.update(with: readOnlyPlugin)
        storage.saveIfNeeded()
    }
}

// MARK: - Mock types
//
private extension PluginListViewModelTests {
    enum MockPluginError: Error {
        case mockError
    }
}
