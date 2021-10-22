import XCTest
@testable import Networking

/// SystemStatusRemote Unit Tests
///
class SystemStatusRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    // MARK: - Load system plugins tests

    /// Verifies that loadSystemPlugins properly parses the sample response.
    ///
    func test_loadSystemPlugins_properly_returns_systemPlugins() {
        let remote = SystemStatusRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "system_status", filename: "systemStatus")

        // When
        let result: Result<[SystemPlugin], Error> = waitFor { promise in
            remote.loadSystemPlugins(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let plugins):
            XCTAssertEqual(plugins.count, 3)
        case .failure(let error):
            XCTAssertNil(error)
        }
    }

    /// Verifies that loadSystemPlugins properly relays Networking Layer errors.
    ///
    func test_loadSystemPlugins_properly_relays_netwoking_errors() {
        let remote = SystemStatusRemote(network: network)

        // When
        let result: Result<[SystemPlugin], Error> = waitFor { promise in
            remote.loadSystemPlugins(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let plugins):
            XCTAssertNil(plugins)
        case .failure(let error):
            XCTAssertNotNil(error)
        }
    }
}
