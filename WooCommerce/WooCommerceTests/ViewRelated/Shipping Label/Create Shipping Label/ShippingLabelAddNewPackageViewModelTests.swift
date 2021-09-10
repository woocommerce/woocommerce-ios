import XCTest
@testable import Yosemite
@testable import WooCommerce

class ShippingLabelAddNewPackageViewModelTests: XCTestCase {

    private let sampleSiteID = 12345

    func test_createCustomPackage_resets_child_view_models_on_success() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = ShippingLabelAddNewPackageViewModel(stores: stores,
                                                            siteID: 12345,
                                                            packagesResponse: ShippingLabelPackagesResponse.fake(),
                                                            onCompletion: {_, _, _ in })

        // Given a validated custom package
        viewModel.customPackageVM.packageType = .letter
        viewModel.customPackageVM.packageName = "Test Package"
        viewModel.customPackageVM.packageHeight = "1"
        viewModel.customPackageVM.packageWidth = "1"
        viewModel.customPackageVM.packageLength = "1"
        viewModel.customPackageVM.emptyPackageWeight = "1"

        // When
        stores.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
            case let .createPackage(_, _, _, onCompletion):
                onCompletion(.success(true))
            case let .packagesDetails(_, onCompletion):
                onCompletion(.success(ShippingLabelPackagesResponse.fake()))
            default:
                break
            }
        }

        viewModel.createCustomPackage(onCompletion: { _ in })

        // Then
        XCTAssertNil(viewModel.customPackageVM.validatedCustomPackage)
        XCTAssertEqual(viewModel.customPackageVM.packageType, .box)
        XCTAssertEqual(viewModel.customPackageVM.packageName, "")
        XCTAssertEqual(viewModel.customPackageVM.packageHeight, "")
        XCTAssertEqual(viewModel.customPackageVM.packageWidth, "")
        XCTAssertEqual(viewModel.customPackageVM.packageLength, "")
        XCTAssertEqual(viewModel.customPackageVM.emptyPackageWeight, "")
    }

    func test_activateServicePackage_resets_child_view_models_on_success() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = ShippingLabelAddNewPackageViewModel(stores: stores,
                                                            siteID: 12345,
                                                            packagesResponse: Mocks.packagesResponse,
                                                            onCompletion: {_, _, _ in })

        // Given changes to child view models
        viewModel.customPackageVM.packageName = "Test Package"
        viewModel.servicePackageVM.selectedPackage = Mocks.predefinedPackage

        // When
        stores.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
            case let .createPackage(_, _, _, onCompletion):
                onCompletion(.success(true))
            case let .packagesDetails(_, onCompletion):
                onCompletion(.success(ShippingLabelPackagesResponse.fake()))
            default:
                break
            }
        }

        viewModel.activateServicePackage(onCompletion: { _ in })

        // Then
        XCTAssertEqual(viewModel.customPackageVM.packageName, "")
        XCTAssertNotEqual(viewModel.servicePackageVM.selectedPackage, Mocks.predefinedPackage)
        XCTAssertFalse(viewModel.servicePackageVM.predefinedOptions.contains(Mocks.predefinedOption))
    }
}

extension ShippingLabelAddNewPackageViewModelTests {
    enum Mocks {
        static let predefinedPackage = ShippingLabelPredefinedPackage(id: "small_flat_box",
                                                                      title: "Small Flat Rate Box",
                                                                      isLetter: false,
                                                                      dimensions: "21.91 x 13.65 x 4.13")
        static let predefinedOption = ShippingLabelPredefinedOption(title: "USPS Priority Mail Flat Rate Boxes",
                                                                    providerID: "usps",
                                                                    predefinedPackages: [predefinedPackage])
        static let packagesResponse = ShippingLabelPackagesResponse(storeOptions: ShippingLabelStoreOptions.fake(),
                                                                    customPackages: [ShippingLabelCustomPackage.fake()],
                                                                    predefinedOptions: [],
                                                                    unactivatedPredefinedOptions: [predefinedOption])
    }
}
