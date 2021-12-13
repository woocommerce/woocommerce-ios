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
        let package1 = ShippingLabelPackageAttributes(packageID: "Box 1", totalWeight: "12", items: [.fake(), .fake(), .fake()])
        let package2 = ShippingLabelPackageAttributes(packageID: "Box 2", totalWeight: "5.5", items: [.fake(), .fake()])

        // When & Then
        let viewModel1 = ShippingLabelPackagesFormViewModel(order: order,
                                                            packagesResponse: nil,
                                                            selectedPackages: [],
                                                            onSelectionCompletion: { _ in },
                                                            onPackageSyncCompletion: { _ in })
        XCTAssertFalse(viewModel1.foundMultiplePackages)

        let viewModel2 = ShippingLabelPackagesFormViewModel(order: order,
                                                            packagesResponse: nil,
                                                            selectedPackages: [package1],
                                                            onSelectionCompletion: { _ in },
                                                            onPackageSyncCompletion: { _ in })
        XCTAssertFalse(viewModel2.foundMultiplePackages)

        let viewModel3 = ShippingLabelPackagesFormViewModel(order: order,
                                                            packagesResponse: nil,
                                                            selectedPackages: [package1, package2],
                                                            onSelectionCompletion: { _ in },
                                                            onPackageSyncCompletion: { _ in })
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
                                                           onSelectionCompletion: { _ in },
                                                           onPackageSyncCompletion: { _ in },
                                                           storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.itemViewModels.count, 1)
        XCTAssertEqual(viewModel.itemViewModels.first?.selectedPackageID, "package-1")
    }

    func test_itemViewModels_returns_correctly_when_initial_selectedPackages_is_not_empty() {
        // Given
        let order = MockOrders().makeOrder().copy(siteID: sampleSiteID)
        let package1 = ShippingLabelPackageAttributes(packageID: "Box 1",
                                                      totalWeight: "12",
                                                      items: [.fake(id: 1),
                                                              .fake(id: 33),
                                                              .fake(id: 23)])
        let package2 = ShippingLabelPackageAttributes(packageID: "Box 2", totalWeight: "5.5", items: [.fake(id: 49)])

        // When
        let viewModel = ShippingLabelPackagesFormViewModel(order: order,
                                                           packagesResponse: nil,
                                                           selectedPackages: [package1, package2],
                                                           onSelectionCompletion: { _ in },
                                                           onPackageSyncCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.itemViewModels.count, 2)
        XCTAssertEqual(viewModel.itemViewModels.first?.selectedPackageID, package1.packageID)
        XCTAssertEqual(viewModel.itemViewModels.last?.selectedPackageID, package2.packageID)
    }

    func test_doneButtonEnabled_returns_true_when_all_packages_are_valid() {
        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let package1 = ShippingLabelPackageAttributes(packageID: "Box 1", totalWeight: "12", items: [.fake(), .fake()])
        let package2 = ShippingLabelPackageAttributes(packageID: "Box 2", totalWeight: "5.5", items: [.fake()])

        // When
        let viewModel = ShippingLabelPackagesFormViewModel(order: order,
                                                           packagesResponse: nil,
                                                           selectedPackages: [package1, package2],
                                                           onSelectionCompletion: { _ in },
                                                           onPackageSyncCompletion: { _ in })

        // Then
        XCTAssertTrue(viewModel.doneButtonEnabled)
    }

    func test_doneButtonEnabled_returns_false_when_not_all_packages_are_valid() {
        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let package1 = ShippingLabelPackageAttributes(packageID: "Box 1", totalWeight: "12", items: [.fake(), .fake()])
        let package2 = ShippingLabelPackageAttributes(packageID: "Box 2", totalWeight: "5.5", items: [.fake()])

        // When
        let viewModel = ShippingLabelPackagesFormViewModel(order: order,
                                                           packagesResponse: nil,
                                                           selectedPackages: [package1, package2],
                                                           onSelectionCompletion: { _ in },
                                                           onPackageSyncCompletion: { _ in })
        viewModel.itemViewModels.first?.totalWeight = "0"

        // Then
        XCTAssertFalse(viewModel.doneButtonEnabled)
    }

    func test_onCompletion_returns_correctly() {
        // Given
        let order = MockOrders().empty().copy(siteID: sampleSiteID)
        let package1 = ShippingLabelPackageAttributes(packageID: "Box 1", totalWeight: "12", items: [.fake(), .fake()])
        let package2 = ShippingLabelPackageAttributes(packageID: "Box 2", totalWeight: "5.5", items: [.fake()])

        var result: [ShippingLabelPackageAttributes] = []
        let completionHandler = { packages in
            result = packages
        }
        // When
        let viewModel = ShippingLabelPackagesFormViewModel(order: order,
                                                           packagesResponse: nil,
                                                           selectedPackages: [package1, package2],
                                                           onSelectionCompletion: completionHandler,
                                                           onPackageSyncCompletion: { _ in })
        viewModel.confirmPackageSelection()

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.packageID, package1.packageID)
        XCTAssertEqual(result.last?.packageID, package2.packageID)
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

extension ShippingLabelPackageItem {
    static func fake(id: Int64 = 1,
                     name: String = "",
                     weight: Double = 1,
                     quantity: Decimal = 1,
                     value: Double = 10,
                     dimensions: Yosemite.ProductDimensions = .fake(),
                     attributes: [VariationAttributeViewModel] = []) -> ShippingLabelPackageItem {
        ShippingLabelPackageItem(productOrVariationID: id,
                                 name: name,
                                 weight: weight,
                                 quantity: quantity,
                                 value: value,
                                 dimensions: dimensions,
                                 attributes: attributes)
    }
}
