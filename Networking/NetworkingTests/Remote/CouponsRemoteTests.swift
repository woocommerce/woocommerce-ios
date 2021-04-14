import XCTest
@testable import Networking
import Alamofire

class CouponsRemoteTests: XCTestCase {

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

    // MARK: - Load all coupons tests

    /// Verifies that loadAllCoupons properly parses the `coupons-all` sample response.
    /// 
    func test_loadAllCoupons_returns_parsed_coupons() {
        // Given
        let remote = CouponsRemote(network: network)
        let expectation = self.expectation(description: "Load All Coupons")

        network.simulateResponse(requestUrlSuffix: "coupons", filename: "coupons-all")

        // When
        var result: (coupons: [Coupon]?, error: Error?)
        remote.loadAllCoupons(for: sampleSiteID) { coupons, error in
            result = (coupons, error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Then
        XCTAssertNil(result.error)
        XCTAssertNotNil(result.coupons)
        XCTAssertEqual(result.coupons?.count, 3)
    }

    /// Verifies that loadAllCoupons uses the passed in parameters to specify the page of results wanted.
    ///
    func test_loadAllCoupons_uses_passed_pagination_parameters() throws {
        // Given
        let remote = CouponsRemote(network: network)

        // When
        remote.loadAllCoupons(for: sampleSiteID, pageNumber: 2, pageSize: 17) { _, _ in }

        // Then
        guard let request = network.requestsForResponseData.first as? JetpackRequest else {
            XCTFail("Expected request not enqueued")
            return
        }
        guard let page = request.parameters["page"] as? String,
              let pageSize = request.parameters["per_page"] as? String else {
            XCTFail("Pagination parameters not found")
            return
        }
        XCTAssertEqual(page, "2")
        XCTAssertEqual(pageSize, "17")
    }

    /// Verifies that loadAllCoupons uses the SiteID passed in for the request.
    ///
    func test_loadAllCoupons_uses_passed_siteID_for_request() {
        // Given
        let remote = CouponsRemote(network: network)

        // When
        remote.loadAllCoupons(for: sampleSiteID) { _, _ in }

        // Then
        guard let request = network.requestsForResponseData.first as? JetpackRequest else {
            XCTFail("Expected request not enqueued")
            return
        }
        XCTAssertEqual(request.siteID, sampleSiteID)
    }

    /// Verifies that loadAllCoupons uses the SiteID passed in to build the models.
    ///
    func test_loadAllCoupons_uses_passed_siteID_for_model_creation() {
        // Given
        let remote = CouponsRemote(network: network)
        let expectation = self.expectation(description: "Load All Coupons")

        network.simulateResponse(requestUrlSuffix: "coupons", filename: "coupons-all")

        // When
        var result: (coupons: [Coupon]?, error: Error?)
        remote.loadAllCoupons(for: sampleSiteID) { coupons, error in
            result = (coupons, error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)

        // Then
        XCTAssertEqual(result.coupons?.first?.siteId, sampleSiteID)
    }
}
