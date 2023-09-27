import XCTest
import Yosemite
@testable import WooCommerce

final class AddProductNameWithAIViewModelTests: XCTestCase {

    func test_productNameContent_is_updated_correctly_with_initialName() {
        // Given
        let expectedName = "iPhone 15"
        let viewModel = AddProductNameWithAIViewModel(siteID: 123, initialName: expectedName, onUsePackagePhoto: { _ in }, onContinueWithProductName: { _ in })

        // Then
        XCTAssertEqual(viewModel.productNameContent, expectedName)
    }

    func test_onUsePackagePhoto_is_triggered_when_tapping_package_photo() {
        // Given
        var triggeredName: String?
        let expectedName = "iPhone 15"
        let viewModel = AddProductNameWithAIViewModel(siteID: 123,
                                                      initialName: expectedName,
                                                      onUsePackagePhoto: { triggeredName = $0 },
                                                      onContinueWithProductName: { _ in })

        // When
        viewModel.didTapUsePackagePhoto()

        // Then
        XCTAssertEqual(triggeredName, expectedName)
    }

    func test_onContinueWithProductName_is_triggered_when_tapping_continue() {
        // Given
        var triggeredName: String?
        let expectedName = "iPhone 15"
        let viewModel = AddProductNameWithAIViewModel(siteID: 123,
                                                      initialName: expectedName,
                                                      onUsePackagePhoto: { _ in },
                                                      onContinueWithProductName: { triggeredName = $0 })

        // When
        viewModel.didTapContinue()

        // Then
        XCTAssertEqual(triggeredName, expectedName)
    }
}
