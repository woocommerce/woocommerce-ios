import XCTest
@testable import Networking


/// JetpackEndpoint Unit Tests
///
class JetpackEndpointTests: XCTestCase {
    
    func testExample() {
        let test = JetpackEndpoint(wooApiVersion: .mark2, method: .get, siteID: 123, path: "test")
    }
}
