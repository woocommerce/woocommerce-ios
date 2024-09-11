import XCTest
@testable import WooCommerce

final class BlazeCampaignDetailWebViewModelTests: XCTestCase {

    func test_onDismiss_is_triggered_when_campaign_list_is_detected() throws {
        // Given
        let siteURL = "https://example.com"
        let initialURL = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/campaigns/134/example.com"))

        var onDismissTriggered = false
        let viewModel = BlazeCampaignDetailWebViewModel(initialURL: initialURL, siteURL: siteURL, onDismiss: {
            onDismissTriggered = true
        }, onCreateCampaign: { _ in })

        // When
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/campaigns/example.com"))
        viewModel.handleRedirect(for: url)

        // Then
        XCTAssertTrue(onDismissTriggered)
    }

    func test_onCreateCampaign_is_triggered_when_campaign_list_is_detected() throws {
        // Given
        let siteURL = "https://example.com"
        let initialURL = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/campaigns/134/example.com"))

        var onCreateCampaignTriggered = false
        var triggeredProductID: Int64?
        let viewModel = BlazeCampaignDetailWebViewModel(initialURL: initialURL, siteURL: siteURL, onDismiss: {}, onCreateCampaign: { productID in
            onCreateCampaignTriggered = true
            triggeredProductID = productID
        })

        // When
        let url = try XCTUnwrap(URL(string: "https://wordpress.com/advertising/campaigns/134/example.com?blazepress-widget=post-1039"))
        viewModel.handleRedirect(for: url)

        // Then
        XCTAssertTrue(onCreateCampaignTriggered)
        XCTAssertEqual(triggeredProductID, 1039)
    }
}
