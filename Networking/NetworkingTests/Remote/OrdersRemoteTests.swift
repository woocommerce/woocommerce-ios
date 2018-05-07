import XCTest
@testable import Networking


/// OrdersRemoteTests:
///
class OrdersRemoteTests: XCTestCase {

    /// Dummy Credentials
    ///
    let credentials = Credentials(authToken: "Dummy!")

    /// Dummy Network Wrapper
    ///
    let network = NetworkMockup()

    /// Dummy Site ID
    ///
    let sampleSiteID = 1234


    /// TODO: This is a stub. To be completed in another PR!
    ///
    func testLoadAllOrdersProperlyReturnsParsedRemoteOrders() {
        let remote = OrdersRemote(credentials: credentials, network: network)
        let expectation = self.expectation(description: "Fetch Order")

        network.simulateResponse(requestUrlSuffix: "/orders", filename: "orders-load-all")

        remote.loadAllOrders(for: sampleSiteID) { orders, error in
// TODO: This is a mockup! Fill me!
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
