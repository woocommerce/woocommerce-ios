import XCTest
@testable import WooCommerce
import Yosemite
@testable import Storage

class ShippingLabelPackagesFormViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 1234

    private var storageManager: StorageManagerType!

    private var storage: StorageType {
        storageManager.viewStorage
    }

    private var stores: MockStoresManager!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting(authenticated: true))
    }

    override func tearDown() {
        storageManager = nil
        stores = nil
        super.tearDown()
    }

    func test_foundMultiplePackages_returns_correctly() {
        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let package1 = ShippingLabelPackageAttributes(packageID: "Box 1", totalWeight: "12", productIDs: [1, 2, 3])
        let package2 = ShippingLabelPackageAttributes(packageID: "Box 2", totalWeight: "5.5", productIDs: [1, 2, 3])

        // When & Then
        let viewModel1 = ShippingLabelPackagesFormViewModel(order: order, packagesResponse: nil, selectedPackages: []) { _ in }
        XCTAssertFalse(viewModel1.foundMultiplePackages)

        let viewModel2 = ShippingLabelPackagesFormViewModel(order: order, packagesResponse: nil, selectedPackages: [package1]) { _ in }
        XCTAssertFalse(viewModel2.foundMultiplePackages)

        let viewModel3 = ShippingLabelPackagesFormViewModel(order: order, packagesResponse: nil, selectedPackages: [package1, package2]) { _ in }
        XCTAssertTrue(viewModel3.foundMultiplePackages)
    }

    func test_itemViewModels_returns_correctly_when_initial_selectedPackages_is_empty() {
        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        insert(MockShippingLabelAccountSettings.sampleAccountSettings(siteID: sampleSiteID, lastSelectedPackageID: "package-1"))

        // When
        let viewModel = ShippingLabelPackagesFormViewModel(order: order,
                                                           packagesResponse: nil,
                                                           selectedPackages: [],
                                                           onCompletion: { _ in },
                                                           storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.itemViewModels.count, 1)
        XCTAssertEqual(viewModel.itemViewModels.first?.selectedPackageID, "package-1")
    }

    func test_itemViewModels_returns_correctly_when_initial_selectedPackages_is_not_empty() {
        // Given
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID)
        let package1 = ShippingLabelPackageAttributes(packageID: "Box 1", totalWeight: "12", productIDs: [1, 33, 23])
        let package2 = ShippingLabelPackageAttributes(packageID: "Box 2", totalWeight: "5.5", productIDs: [49])

        // When
        let viewModel = ShippingLabelPackagesFormViewModel(order: order,
                                                           packagesResponse: nil,
                                                           selectedPackages: [package1, package2]) { _ in }

        // Then
        XCTAssertEqual(viewModel.itemViewModels.count, 2)
        XCTAssertEqual(viewModel.itemViewModels.first?.selectedPackageID, package1.packageID)
        XCTAssertEqual(viewModel.itemViewModels.last?.selectedPackageID, package2.packageID)
    }

}

// MARK: - Utils
private extension ShippingLabelPackagesFormViewModelTests {
    func insert(_ readOnlyOrderProduct: Yosemite.Product) {
        let product = storage.insertNewObject(ofType: StorageProduct.self)
        product.update(with: readOnlyOrderProduct)
    }

    func insert(_ readOnlyOrderProductVariation: Yosemite.ProductVariation) {
        let productVariation = storage.insertNewObject(ofType: StorageProductVariation.self)
        productVariation.update(with: readOnlyOrderProductVariation)
    }

    func insert(_ readOnlyAccountSettings: Yosemite.ShippingLabelAccountSettings) {
        let accountSettings = storage.insertNewObject(ofType: StorageShippingLabelAccountSettings.self)
        accountSettings.update(with: readOnlyAccountSettings)
    }
}
