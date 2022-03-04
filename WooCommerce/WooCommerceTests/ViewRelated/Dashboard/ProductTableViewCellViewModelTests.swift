import XCTest
import Yosemite
@testable import WooCommerce

final class ProductTableViewCellViewModelTests: XCTestCase {
    func test_viewModel_with_TopEarnerStatsItem_sets_properties_correctly() {
        // Given
        let statsItem = TopEarnerStatsItem.fake().copy(productName: "Kiwi 🥝",
                                                       quantity: 5,
                                                       total: 3888.822,
                                                       currency: CurrencySettings.CurrencyCode.USD.rawValue,
                                                       imageUrl: "wp.com/kiwi-image")
        let currencyFormatter = CurrencyFormatter(currencySettings: CurrencySettings())

        // When
        let viewModel = ProductTableViewCell.ViewModel(statsItem: statsItem, currencyFormatter: currencyFormatter)

        // Then
        XCTAssertEqual(viewModel.nameText, "Kiwi 🥝")
        let expectedDetailText = String.localizedStringWithFormat(
            NSLocalizedString("Net sales: %@",
                              comment: "Top performers — label for the total sales of a product"),
            "$3,888.82"
        )
        XCTAssertEqual(viewModel.detailText, expectedDetailText)
        XCTAssertEqual(viewModel.accessoryText, "5")
        XCTAssertEqual(viewModel.imageURL, "wp.com/kiwi-image")
    }
}
