import XCTest
@testable import Networking

/// CreateBlazeCampaign Unit Tests
///
final class CreateBlazeCampaignTests: XCTestCase {
    func test_initializing_using_destination_url() {
        // Given
        let destinationURL = "https://example.com/product/fantastic-silk-table?Tea=test&book=long&cover_notes=resume"

        // When
        let sut = CreateBlazeCampaign(origin: "",
                                      originVersion: "",
                                      paymentMethodID: "",
                                      startDate: Date(),
                                      endDate: Date(),
                                      timeZone: "",
                                      totalBudget: 10.0,
                                      siteName: "",
                                      textSnippet: "",
                                      destinationURL: destinationURL,
                                      mainImage: .fake(),
                                      targeting: nil,
                                      targetUrn: "",
                                      type: "")

        // Then
        XCTAssertEqual(sut.targetUrl, "https://example.com/product/fantastic-silk-table")
        XCTAssertEqual(sut.urlParams, "Tea=test&book=long&cover_notes=resume")
    }
}
