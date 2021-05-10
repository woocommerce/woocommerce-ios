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
        viewModel.activate {}

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
}

private extension PluginListViewModelTests {
    func insert(_ readOnlyPlugin: Yosemite.SitePlugin) {
        let plugin = storage.insertNewObject(ofType: StorageSitePlugin.self)
        plugin.update(with: readOnlyPlugin)
    }
}

final class MockPluginStoresManager: DefaultStoresManager {
    /// Whether synchronizePlugins action was triggered.
    ///
    var invokedSynchronizePlugins = false
    
    /// The site ID that the `synchronizePlugins` action was triggered with.
    ///
    var invokedSynchronizePluginsWithSiteID: Int64 = 0
    
    /// Whether the mock `synchronizePlugins` action handler should succeed.
    ///
    private let shouldSucceed: Bool
    
    /// Delay time for completion block of the mock `synchronizePlugins` action.
    ///
    private let completionDelay: TimeInterval

    enum MockPluginError: Error {
        case mockError
    }

    init(shouldSucceed: Bool, completionDelay: TimeInterval = 0) {
        self.shouldSucceed = shouldSucceed
        self.completionDelay = completionDelay
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
            DispatchQueue.main.asyncAfter(deadline: .now() + completionDelay) { [weak self] in
                if self?.shouldSucceed == true {
                    onCompletion(.success(()))
                } else {
                    onCompletion(.failure(MockPluginError.mockError))
                }
            }
        }
    }
}
