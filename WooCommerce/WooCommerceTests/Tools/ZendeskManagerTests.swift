import XCTest
@testable import WooCommerce


/// Zendesk Manager Tests
///
class ZendeskManagerTests: XCTestCase {

    /// Shared instance of ZendeskManager.
    ///
    private var zendesk: ZendeskManager!

    /// The Zendesk web portal URL.
    ///
    private let zdUrl = "https://automattic.zendesk.com"

    /// Default ticket tags.
    ///
    private let zdTags = ["iOS", "woo-mobile-sdk", "jetpack"]

    /// Ensure the Zendesk URL is set to the parent brand.
    ///
    func testZendeskUrl() {
        XCTAssertEqual(ApiCredentials.zendeskUrl, zdUrl)
    }

    /// Test default tags return as expected.
    ///
    func testZendeskDefaultTags() {
        let tags = ZendeskManager.shared.getTags(supportSourceTag: nil)
        XCTAssert(tags.count >= 3, "Test failed: expected a minimum of 3 default tags.")
        XCTAssert(zdTags.count == 3, "Test failed: expected 3 default tags.")
        for index in 0..<zdTags.count {
            XCTAssertEqual(zdTags[index], tags[index])
        }
    }

    // MARK: - Overridden Methods
    //
    override func setUp() {
        super.setUp()

        setupZendesk()
    }

    func setupZendesk() {
        ZendeskManager.shared.initialize()
    }
}
