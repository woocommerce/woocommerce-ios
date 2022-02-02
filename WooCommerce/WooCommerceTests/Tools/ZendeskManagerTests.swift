import XCTest
@testable import WooCommerce


/// Zendesk Manager Tests
///
class ZendeskManagerTests: XCTestCase {

    /// Shared instance of ZendeskManager.
    ///
    private var zendesk: ZendeskManager!

    /// Default ticket tags.
    ///
    private let zdTags = ["iOS", "woo-mobile-sdk", "jetpack"]

    /// Test default tags return as expected.
    ///
    func testZendeskDefaultTags() {
        let tags = ZendeskProvider.shared.getTags(supportSourceTag: nil)
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
        ZendeskProvider.shared.initialize()
    }
}
