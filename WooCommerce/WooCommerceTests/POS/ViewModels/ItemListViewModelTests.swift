import XCTest
import Combine
@testable import WooCommerce
@testable import protocol Yosemite.POSItem

final class ItemListViewModelTests: XCTestCase {
    private var posModel: MockPointOfSaleAggregateModel!
    private var sut: ItemListViewModel!

    private var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        posModel = MockPointOfSaleAggregateModel(itemListState: .initialLoading)
        sut = ItemListViewModel(posModel: posModel)
    }

    override func tearDown() {
        posModel = nil
        sut = nil
        UserDefaults.standard.set(nil, forKey: ItemListViewModel.BannerState.isSimpleProductsOnlyBannerDismissedKey)
        super.tearDown()
    }

    func test_isHeaderBannerDismissed_when_dismissBanner_is_called_then_returns_true() {
        // Given
        XCTAssertEqual(sut.isHeaderBannerDismissed, false)

        // When
        sut.dismissBanner()

        // Then
        XCTAssertEqual(sut.isHeaderBannerDismissed, true)
    }
}
