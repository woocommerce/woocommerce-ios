import XCTest
@testable import WooCommerce
import Yosemite

final class ShippingLabelPackageSelectedViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 1234

    func test_syncPackageDetails_returns_expected_values_if_succeeded() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let expectedResponse = samplePackagesResponse()

        // When
        stores.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
            case let .packagesDetails(_, onCompletion):
                onCompletion(.success(expectedResponse))
            default:
                break
            }
        }

        let viewModel = ShippingLabelPackageSelectedViewModel(siteID: sampleSiteID, stores: stores)

        // Then
        XCTAssertEqual(viewModel.packagesResponse, expectedResponse)
        XCTAssertEqual(viewModel.state, .results)
    }

    func test_syncPackageDetails_returns_expected_values_if_fails() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let error = SampleError.first

        // When
        stores.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
            case let .packagesDetails(_, onCompletion):
                onCompletion(.failure(error))
            default:
                break
            }
        }

        let viewModel = ShippingLabelPackageSelectedViewModel(siteID: sampleSiteID, stores: stores)

        // Then
        XCTAssertNil(viewModel.packagesResponse)
        XCTAssertEqual(viewModel.state, .error)
    }
}

private extension ShippingLabelPackageSelectedViewModelTests {
    func samplePackagesResponse() -> ShippingLabelPackagesResponse {
        let storeOptions = ShippingLabelStoreOptions(currencySymbol: "$", dimensionUnit: "in", weightUnit: "oz", originCountry: "US")

        let customPackages = [
            ShippingLabelCustomPackage(isUserDefined: true, title: "Box", isLetter: true, dimensions: "3 x 10 x 4", boxWeight: 10, maxWeight: 11),
                              ShippingLabelCustomPackage(isUserDefined: true,
                                                         title: "Box n°2",
                                                         isLetter: true,
                                                         dimensions: "30 x 1 x 20",
                                                         boxWeight: 2,
                                                         maxWeight: 4),
                              ShippingLabelCustomPackage(isUserDefined: true,
                                                         title: "Box n°3",
                                                         isLetter: true,
                                                         dimensions: "10 x 40 x 3",
                                                         boxWeight: 7,
                                                         maxWeight: 10)]


        let predefinedOptions = [ShippingLabelPredefinedOption(title: "USPS", predefinedPackages: [ShippingLabelPredefinedPackage(id: "package-1",
                                                                                                                                title: "Small",
                                                                                                                                isLetter: true,
                                                                                                                                dimensions: "3 x 4 x 5"),
                                                                                                 ShippingLabelPredefinedPackage(id: "package-2",
                                                                                                                                title: "Big",
                                                                                                                                isLetter: true,
                                                                                                                                dimensions: "5 x 7 x 9")])]

        return ShippingLabelPackagesResponse(storeOptions: storeOptions, customPackages: customPackages, predefinedOptions: predefinedOptions)
    }
}
