import XCTest
@testable import Yosemite
@testable import Networking


/// SitePostStore Unit Tests
///
class SitePostStoreTests: XCTestCase {

    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!


    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 3584907

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }

    /// Get site post password
       ///
//       case getSitePostPassword(siteID: Int64, postID: Int64, onCompletion: (_ password: String?, _ error: Error?) -> Void)
//
//       /// Update site post password
//       ///
//       case updateSitePostPassword(siteID: Int64, postID: Int64, password: String, onCompletion: (_ password: String?, _ error: Error?) -> Void)

    // MARK: - SitePostAction.getSitePostPassword

    /// Verifies that SitePostAction.getSitePostPassword returns the expected result.
    ///
    func testRetrieveSitePostPasswordReturnsExpectedResult() {
        let expectation = self.expectation(description: "Retrieve site post password")
        let sitePostStore = SitePostStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let postID: Int64 = 7

        network.simulateResponse(requestUrlSuffix: "/sites/\(sampleSiteID)/posts/\(postID)", filename: "site-post")
        let action = SitePostAction.retrieveSitePostPassword(siteID: sampleSiteID, postID: postID) { (password, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(password)
            XCTAssertEqual(password, "woooooooo!")
            expectation.fulfill()
        }

        sitePostStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

}
