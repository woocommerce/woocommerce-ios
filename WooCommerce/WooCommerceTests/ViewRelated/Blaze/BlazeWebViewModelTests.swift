import XCTest
import Yosemite
@testable import WooCommerce

final class BlazeWebViewModelTests: XCTestCase {
    // MARK: - `initialURL`

    func test_initialURL_includes_source_and_siteURL_and_productID_when_product_is_available() {
        // Given
        let source: BlazeSource = .campaignList
        let siteURL = "https://example.com"
        let productID: Int64? = 134
        let viewModel = BlazeWebViewModel(source: source, siteURL: siteURL, productID: productID)

        // Then
        XCTAssertEqual(viewModel.initialURL, URL(string: "https://wordpress.com/advertising/example.com?blazepress-widget=post-134&source=campaign_list"))
    }

    func test_initialURL_includes_source_and_siteURL_when_product_is_unavailable() {
        // Given
        let source: BlazeSource = .productMoreMenu
        let siteURL = "https://example.com"
        let viewModel = BlazeWebViewModel(source: source, siteURL: siteURL, productID: nil)

        // Then
        XCTAssertEqual(viewModel.initialURL, URL(string: "https://wordpress.com/advertising/example.com?source=product_more_menu"))
    }
}
