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
}
