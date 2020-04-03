import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductSettingsViewModelTests: XCTestCase {

    func testOnReloadClosure() {

        let product = MockProduct().product(status: .publish)
        let viewModel = ProductSettingsViewModel(product: product)

        // Act
        let expectation = self.expectation(description: "Wait for the view model data to be updated")

        viewModel.onReload = {
            expectation.fulfill()
        }

        // Update settings. Section data changed. This will update the view model, and will fire the `onReload` closure.
        viewModel.productSettings = ProductSettings(status: product.productStatus)

        waitForExpectations(timeout: 1.5, handler: nil)
    }

    func testHasUnsavedChanges() {
        let product = MockProduct().product(status: .publish)
        let viewModel = ProductSettingsViewModel(product: product)

        XCTAssertFalse(viewModel.hasUnsavedChanges())

        viewModel.productSettings.status = .pending

        XCTAssertTrue(viewModel.hasUnsavedChanges())
    }

}
