import XCTest
import Yosemite
@testable import WooCommerce

final class BlazeWebViewModelTests: XCTestCase {

    private let sampleSiteID: Int64 = 123

    func test_initialURL_includes_source_and_siteURL_and_productID_when_product_is_available() {
        // Given
        let source: BlazeSource = .campaignList
        let siteURL = "https://example.com"
        let productID: Int64? = 134
        let viewModel = BlazeWebViewModel(siteID: sampleSiteID, source: source, siteURL: siteURL, productID: productID)

        // Then
        XCTAssertEqual(viewModel.initialURL, URL(string: "https://wordpress.com/advertising/example.com?blazepress-widget=post-134&source=campaign_list"))
    }

    func test_initialURL_includes_source_and_siteURL_when_product_is_unavailable() {
        // Given
        let source: BlazeSource = .productDetailPromoteButton
        let siteURL = "https://example.com"
        let viewModel = BlazeWebViewModel(siteID: sampleSiteID, source: source, siteURL: siteURL, productID: nil)

        // Then
        XCTAssertEqual(viewModel.initialURL, URL(string: "https://wordpress.com/advertising/example.com?source=product_detail_promote_button"))
    }
}
