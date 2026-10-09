import Testing
import Yosemite
@testable import PointOfSale

struct PointOfSaleViewStateCoordinatorTests {
    @Test func test_reset_when_new_cart_starts_then_clears_navigation_and_cash_draft() {
        // Given
        let sut = PointOfSaleViewStateCoordinator()
        sut.selectedItemListType = .coupons(search: true)
        sut.searchTerm = "discount"
        sut.itemNavigationPath = [.variableParentProduct(.init(id: .init(underlyingType: .product, itemID: 1),
                                                             name: "Product", productImageSource: nil, productID: 1))]
        sut.cashAmountInput = .init(amount: "6.00", displayText: "6.00", inputDigits: "600",
                                   hasAppliedPreset: true, isDisplayingPreset: false,
                                   isSubmitting: true, errorMessage: "Failed")

        // When
        sut.reset()

        // Then
        #expect(sut.selectedItemListType == .products(search: false))
        #expect(sut.searchTerm.isEmpty)
        #expect(sut.itemNavigationPath.isEmpty)
        #expect(sut.cashAmountInput == POSCashAmountInputState())
    }
}
