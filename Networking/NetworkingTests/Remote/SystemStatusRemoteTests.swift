import XCTest
@testable import Networking

/// SystemStatusRemote Unit Tests
///
final class SystemStatusRemoteTests: XCTestCase {

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

    /// Verifies that loadSystemInformation properly parses the sample response.
    ///
    func test_loadSystemInformation_properly_returns_site_information() {
        let remote = SystemStatusRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "system_status", filename: "systemStatus")

        // When
        let result: Result<SystemStatus, Error> = waitFor { promise in
            remote.loadSystemInformation(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let systemInfo):
            XCTAssertEqual(systemInfo.activePlugins.count, 4)
            XCTAssertEqual(systemInfo.inactivePlugins.count, 2)
            XCTAssertEqual(systemInfo.environment?.storeID, "sample-store-uuid")
        case .failure(let error):
            XCTAssertNil(error)
        }
    }

    /// Verifies that loadSystemInformation properly relays Networking Layer errors.
    ///
    func test_loadSystemInformation_properly_relays_netwoking_errors() {
        let remote = SystemStatusRemote(network: network)

        // When
        let result: Result<SystemStatus, Error> = waitFor { promise in
            remote.loadSystemInformation(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let systemInformation):
            XCTAssertNil(systemInformation)
        case .failure(let error):
            XCTAssertNotNil(error)
        }
    }

    func test_fetchSystemStatusReport_properly_returns_systemStatus() {
        let remote = SystemStatusRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "system_status", filename: "systemStatus")

        // When
        let result: Result<SystemStatus, Error> = waitFor { promise in
            remote.fetchSystemStatusReport(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        switch result {
        case .success(let report):
            XCTAssertEqual(report.environment?.homeURL, "https://additional-beetle.jurassic.ninja")
            XCTAssertEqual(report.database?.wcDatabaseVersion, "5.9.0")
            XCTAssertEqual(report.activePlugins.count, 4)
            XCTAssertEqual(report.inactivePlugins.count, 2)
            XCTAssertEqual(report.theme?.name, "Twenty Twenty-One")
            XCTAssertEqual(report.settings?.apiEnabled, false)
            XCTAssertEqual(report.security?.secureConnection, true)
            XCTAssertEqual(report.pages.count, 5)
            XCTAssertEqual(report.postTypeCounts.count, 3)
        case .failure(let error):
            XCTAssertNil(error)
        }
    }

    func test_fetchSystemStatusReport_properly_relays_netwoking_errors() {
        let remote = SystemStatusRemote(network: network)

        // When
        let result: Result<SystemStatus, Error> = waitFor { promise in
            remote.fetchSystemStatusReport(for: self.sampleSiteID) { result in
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
