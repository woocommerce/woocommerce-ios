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

    func test_numberOfSections_is_correct_for_active_and_no_inactive_plugins() {
        // Given
        let activePlugin = SitePlugin.fake().copy(siteID: sampleSiteID, status: .active, name: "BBB")
        insert(activePlugin)

        let viewModel = PluginListViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.observePlugins {}

        // Then
        XCTAssertEqual(viewModel.numberOfSections, 1)
    }

    func test_numberOfSections_is_correct_for_inactive_and_no_active_plugins() {
        // Given
        let inactivePlugin = SitePlugin.fake().copy(siteID: sampleSiteID, status: .inactive, name: "CCC")
        insert(inactivePlugin)

        let viewModel = PluginListViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.observePlugins {}

        // Then
        XCTAssertEqual(viewModel.numberOfSections, 1)
    }

    func test_numberOfSections_is_correct_for_active_and_inactive_plugins() {
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
        XCTAssertEqual(viewModel.cellModelForRow(at: IndexPath(row: 0, section: 0)).description, "Lorem ipsum random HTML content")
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

    func test_cellModel_description_html_tags_are_removed() {
        // Given
        let activePlugin = SitePlugin.fake().copy(
            siteID: sampleSiteID,
            status: .active,
            name: "BBB",
            descriptionRaw: "Lorem ipsum random <strong>HTML</strong> <i>content</i>"
        )
        insert(activePlugin)

        let viewModel = PluginListViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.observePlugins {}

        // Then
        XCTAssertEqual(viewModel.cellModelForRow(at: IndexPath(row: 0, section: 0)).description, "Lorem ipsum random HTML content")
    }
}

private extension PluginListViewModelTests {
    func insert(_ readOnlyPlugin: Yosemite.SitePlugin) {
        let plugin = storage.insertNewObject(ofType: StorageSitePlugin.self)
        plugin.update(with: readOnlyPlugin)
    }
}
