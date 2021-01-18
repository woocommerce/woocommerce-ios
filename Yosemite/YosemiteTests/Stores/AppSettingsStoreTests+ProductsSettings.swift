import XCTest
@testable import Yosemite
@testable import Storage

final class AppSettingsStoreTests_ProductsSettings: XCTestCase {
    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock File Storage: Load data in memory
    ///
    private var fileStorage: MockInMemoryStorage!

    /// Test subject
    ///
    private var subject: AppSettingsStore!

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        fileStorage = MockInMemoryStorage()
        subject = AppSettingsStore(dispatcher: dispatcher!, storageManager: storageManager!, fileStorage: fileStorage!)
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        fileStorage = nil
        subject = nil
        super.tearDown()
    }

    func test_productsSettings_actions_returns_values_after_being_set() throws {
        // Given
        let siteID: Int64 = 134
        let productSettings = StoredProductSettings.Setting(siteID: siteID,
                                                            sort: ProductsSortOrder.dateAscending.rawValue,
                                                            stockStatusFilter: .outOfStock,
                                                            productStatusFilter: .pending,
                                                            productTypeFilter: .simple)

        // When
        let result: Result<StoredProductSettings.Setting, Error> = try waitFor { promise in
            let initialReadAction = AppSettingsAction.loadProductsSettings(siteID: siteID) { (result) in
                promise(result)
            }
            self.subject.onAction(initialReadAction)
        }
        /// Before any write actions, the products settings should be nil.
        XCTAssertTrue(result.isFailure)

        let writeAction = AppSettingsAction.upsertProductsSettings(siteID: siteID,
                                                                   sort: productSettings.sort,
                                                                   stockStatusFilter: productSettings.stockStatusFilter,
                                                                   productStatusFilter: productSettings.productStatusFilter,
                                                                   productTypeFilter: productSettings.productTypeFilter) { (error) in
            XCTAssertNil(error)
        }
        subject.onAction(writeAction)


        // Then
        let result2: Result<StoredProductSettings.Setting, Error> = try waitFor { promise in
            let readAction = AppSettingsAction.loadProductsSettings(siteID: siteID) { (result) in
                promise(result)
            }
            self.subject.onAction(readAction)
        }

        XCTAssertTrue(result2.isSuccess)
        XCTAssertEqual(try result2.get(), productSettings)
    }

    func test_productsSettings_actions_returns_values_after_being_set_with_two_sites() throws {
        // Given
        let siteID1: Int64 = 134
        let siteID2: Int64 = 268
        let productSettings1 = StoredProductSettings.Setting(siteID: siteID1,
                                                             sort: ProductsSortOrder.dateAscending.rawValue,
                                                             stockStatusFilter: .outOfStock,
                                                             productStatusFilter: .pending,
                                                             productTypeFilter: .simple)
        let productSettings2 = StoredProductSettings.Setting(siteID: siteID2,
                                                             sort: ProductsSortOrder.nameAscending.rawValue,
                                                             stockStatusFilter: .inStock,
                                                             productStatusFilter: .draft,
                                                             productTypeFilter: .grouped)

        // When
        let writeAction1 = AppSettingsAction.upsertProductsSettings(siteID: siteID1,
                                                                    sort: productSettings1.sort,
                                                                    stockStatusFilter: productSettings1.stockStatusFilter,
                                                                    productStatusFilter: productSettings1.productStatusFilter,
                                                                    productTypeFilter: productSettings1.productTypeFilter) { (error) in
            XCTAssertNil(error)
        }
        subject.onAction(writeAction1)

        let writeAction2 = AppSettingsAction.upsertProductsSettings(siteID: siteID2,
                                                                    sort: productSettings2.sort,
                                                                    stockStatusFilter: productSettings2.stockStatusFilter,
                                                                    productStatusFilter: productSettings2.productStatusFilter,
                                                                    productTypeFilter: productSettings2.productTypeFilter) { (error) in
            XCTAssertNil(error)
        }
        subject.onAction(writeAction2)

        // Then
        let result1: Result<StoredProductSettings.Setting, Error> = try waitFor { promise in
            let initialReadAction = AppSettingsAction.loadProductsSettings(siteID: siteID1) { (result) in
                promise(result)
            }
            self.subject.onAction(initialReadAction)
        }
        XCTAssertTrue(result1.isSuccess)
        XCTAssertEqual(try result1.get(), productSettings1)

        let result2: Result<StoredProductSettings.Setting, Error> = try waitFor { promise in
            let readAction = AppSettingsAction.loadProductsSettings(siteID: siteID2) { (result) in
                promise(result)
            }
            self.subject.onAction(readAction)
        }
        XCTAssertTrue(result2.isSuccess)
        XCTAssertEqual(try result2.get(), productSettings2)
    }

    func test_reset_productsSettings_action() {

        let action = AppSettingsAction.resetProductsSettings
        subject.onAction(action)
        XCTAssertTrue(fileStorage!.deleteIsHit)
    }
}
