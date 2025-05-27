import XCTest
@testable import Networking

final class AddOnGroupRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private var network: MockNetwork!

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    func test_loadAddOnGroups_returns_the_correctly_number_of_addOns() throws {
        // Given
        let remote = AddOnGroupRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "product-add-ons", filename: "add-on-groups")

        // When
        let result: Result<[AddOnGroup], Error> = waitFor { promise in
            remote.loadAddOnGroups(siteID: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        let addOnGroups = try XCTUnwrap(result.get())
        XCTAssertEqual(addOnGroups.count, 2)
    }

    func test_loadAddOnGroups_returns_the_correctly_relays_errors() throws {
        // Given
        let sampleError = NSError(domain: "AddOnGroup", code: 1, userInfo: nil)
        let remote = AddOnGroupRemote(network: network)
        network.simulateError(requestUrlSuffix: "product-add-ons", error: sampleError)

        // When
        let result: Result<[AddOnGroup], Error> = waitFor { promise in
            remote.loadAddOnGroups(siteID: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        let errorFound = try XCTUnwrap(result.failure as NSError?)
        XCTAssertEqual(errorFound, sampleError)
    }
}
