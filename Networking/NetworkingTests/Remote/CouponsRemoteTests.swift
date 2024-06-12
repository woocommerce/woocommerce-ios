import XCTest
@testable import Networking

final class CouponsRemoteTests: XCTestCase {

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

    // MARK: - Load all Coupons tests

    /// Verifies that loadAllCoupons properly parses the `coupons-all` sample response.
    ///
    func test_loadAllCoupons_returns_parsed_coupons() throws {
        // Given
        let remote = CouponsRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "coupons", filename: "coupons-all")

        // When
        let result = waitFor { promise in
            remote.loadAllCoupons(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isSuccess)
        let coupons = try XCTUnwrap(result.get())
        XCTAssertEqual(coupons.count, 4)
    }

    /// Verifies that loadAllCoupons uses the passed in parameters to specify the page of results wanted.
    ///
    func test_loadAllCoupons_uses_passed_pagination_parameters() throws {
        // Given
        let remote = CouponsRemote(network: network)

        // When
        remote.loadAllCoupons(for: sampleSiteID, pageNumber: 2, pageSize: 17) { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.first as? JetpackRequest)
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
    func test_loadAllCoupons_uses_passed_siteID_for_request() throws {
        // Given
        let remote = CouponsRemote(network: network)

        // When
        remote.loadAllCoupons(for: sampleSiteID) { _ in }

        // Then
        let request = try XCTUnwrap(network.requestsForResponseData.first as? JetpackRequest)
        XCTAssertEqual(request.siteID, sampleSiteID)
    }

    /// Verifies that loadAllCoupons uses the SiteID passed in to build the models.
    ///
    func test_loadAllCoupons_uses_passed_siteID_for_model_creation() throws {
        // Given
        let remote = CouponsRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "coupons", filename: "coupons-all")

        // When
        let result = waitFor { promise in
            remote.loadAllCoupons(for: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        let coupons = try result.get()
        XCTAssertEqual(coupons.first?.siteID, sampleSiteID)
    }

    /// Verifies that loadAllCoupons properly relays Networking Layer errors.
    ///
    func test_loadAllCoupons_properly_relays_networking_errors() throws {
        // Given
        let remote = CouponsRemote(network: network)

        let error = NetworkError.unacceptableStatusCode(statusCode: 403)
        network.simulateError(requestUrlSuffix: "coupons", error: error)

        // When
        let result = waitFor { promise in
            remote.loadAllCoupons(for: self.sampleSiteID,
                                  completion: { (result) in
                                    promise(result)
                                })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let resultError = try XCTUnwrap(result.failure as? NetworkError)
        XCTAssertEqual(resultError, .unacceptableStatusCode(statusCode: 403))
    }

    // MARK: - Delete Coupon tests

    /// Verifies that deleteCoupon properly parses the `coupon` sample response.
    ///
    func test_deleteCoupon_properly_returns_parsed_Coupon() throws {
        // Given
        let remote = CouponsRemote(network: network)
        let sampleCouponID: Int64 = 720

        network.simulateResponse(requestUrlSuffix: "coupons/\(sampleCouponID)", filename: "coupon")

        // When
        let result = waitFor { promise in
            remote.deleteCoupon(for: self.sampleSiteID, couponID: sampleCouponID) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isSuccess)
        let coupon = try XCTUnwrap(result.get())
        XCTAssertEqual(coupon.couponID, sampleCouponID)
    }

    /// Verifies that deleteCoupon properly relays Networking Layer errors.
    ///
    func test_deleteCoupon_properly_relays_networking_errors() throws {
        // Given
        let remote = CouponsRemote(network: network)
        let sampleCouponID: Int64 = 1275

        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "coupons/\(sampleCouponID)", error: error)

        // When
        let result = waitFor { promise in
            remote.deleteCoupon(for: self.sampleSiteID,
                                couponID: sampleCouponID,
                                completion: { (result) in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let resultError = try XCTUnwrap(result.failure as? NetworkError)
        XCTAssertEqual(resultError, .unacceptableStatusCode(statusCode: 500))
    }

    // MARK: - Update coupon tests

    /// Verifies that updateCoupon properly parses the `Coupon` sample response.
    ///
    func test_updateCoupon_properly_returns_parsed_coupon() throws {
        // Given
        let remote = CouponsRemote(network: network)
        let coupon = sampleCoupon()
        network.simulateResponse(requestUrlSuffix: "coupons/\(coupon.couponID)", filename: "coupon")

        // When
        let result = waitFor { promise in
            remote.updateCoupon(coupon) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isSuccess)
        let returnedCoupon = try XCTUnwrap(result.get())
        XCTAssertEqual(returnedCoupon, coupon)
    }

    /// Verifies that updateCoupon properly relays Networking Layer errors.
    ///
    func test_updateCoupon_properly_relays_networking_errors() throws {
        // Given
        let remote = CouponsRemote(network: network)
        let coupon = sampleCoupon()

        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "coupons/\(coupon.couponID)", error: error)

        // When
        let result = waitFor { promise in
            remote.updateCoupon(coupon) { (result) in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let resultError = try XCTUnwrap(result.failure as? NetworkError)
        XCTAssertEqual(resultError, .unacceptableStatusCode(statusCode: 500))
    }

    // MARK: - Create coupon tests

    /// Verifies that createCoupon properly parses the `Coupon` sample response.
    ///
    func test_createCoupon_properly_returns_parsed_coupon() throws {
        // Given
        let remote = CouponsRemote(network: network)
        let coupon = sampleCoupon()
        network.simulateResponse(requestUrlSuffix: "coupons", filename: "coupon")

        // When
        let result = waitFor { promise in
            remote.createCoupon(coupon) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isSuccess)
        let returnedCoupon = try XCTUnwrap(result.get())
        XCTAssertEqual(returnedCoupon, coupon)
    }

    /// Verifies that createCoupon properly relays Networking Layer errors.
    ///
    func test_createCoupon_properly_relays_networking_errors() throws {
        // Given
        let remote = CouponsRemote(network: network)
        let coupon = sampleCoupon()

        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "coupons", error: error)

        // When
        let result = waitFor { promise in
            remote.createCoupon(coupon) { (result) in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let resultError = try XCTUnwrap(result.failure as? NetworkError)
        XCTAssertEqual(resultError, .unacceptableStatusCode(statusCode: 500))
    }

    // MARK: - Load coupon report

    /// Verifies that loadCouponReport properly parses the `coupon-reports` sample response.
    ///
    func test_loadCouponReport_properly_returns_parsed_report() throws {
        // Given
        let remote = CouponsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "reports/coupons", filename: "coupon-reports")

        // When
        let result = waitFor { promise in
            remote.loadCouponReport(for: self.sampleSiteID, couponID: 571, from: Date()) { (result) in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isSuccess)
        let returnedReport = try XCTUnwrap(result.get())
        let expectedReport = CouponReport(couponID: 571, amount: 12, ordersCount: 1)
        XCTAssertEqual(returnedReport, expectedReport)
    }

    /// Verifies that loadCouponReport properly relays Networking Layer errors.
    ///
    func test_loadCouponReport_properly_relays_networking_errors() throws {
        // Given
        let remote = CouponsRemote(network: network)

        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "reports/coupons", error: error)

        // When
        let result = waitFor { promise in
            remote.loadCouponReport(for: self.sampleSiteID, couponID: 571, from: Date()) { (result) in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let resultError = try XCTUnwrap(result.failure as? NetworkError)
        XCTAssertEqual(resultError, .unacceptableStatusCode(statusCode: 500))
    }

    // MARK: - Load most active coupons

    /// Verifies that loadMostActiveCoupons properly parses the `coupon-reports` sample response.
    ///
    func test_loadMostActiveCoupons_properly_returns_parsed_report() throws {
        // Given
        let remote = CouponsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "reports/coupons", filename: "coupon-reports")

        // When
        let result = waitFor { promise in
            remote.loadMostActiveCoupons(for: self.sampleSiteID,
                                         numberOfCouponsToLoad: 3,
                                         from: Date(),
                                         to: Date()
            ) { (result) in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isSuccess)
        let returnedReport = try XCTUnwrap(result.get())
        let expectedReport = [CouponReport(couponID: 571, amount: 12, ordersCount: 1)]
        XCTAssertEqual(returnedReport, expectedReport)
    }

    /// Verifies that loadMostActiveCoupons properly relays Networking Layer errors.
    ///
    func test_loadMostActiveCoupons_properly_relays_networking_errors() throws {
        // Given
        let remote = CouponsRemote(network: network)

        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "reports/coupons", error: error)

        // When
        let result = waitFor { promise in
            remote.loadMostActiveCoupons(for: self.sampleSiteID,
                                         numberOfCouponsToLoad: 3,
                                         from: Date(),
                                         to: Date()
            ) { (result) in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let resultError = try XCTUnwrap(result.failure as? NetworkError)
        XCTAssertEqual(resultError, .unacceptableStatusCode(statusCode: 500))
    }

    // MARK: - Load coupons

    /// Verifies that loadCoupons properly parses the `coupons-all` sample response.
    ///
    func test_loadCoupons_properly_returns_parsed_report() throws {
        // Given
        let remote = CouponsRemote(network: network)

        network.simulateResponse(requestUrlSuffix: "coupons", filename: "coupons-all")

        // When
        let result = waitFor { promise in
            remote.loadCoupons(for: self.sampleSiteID,
                               by: [1, 2, 3, 4]) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isSuccess)
        let coupons = try XCTUnwrap(result.get())
        XCTAssertEqual(coupons.count, 4)
    }

    /// Verifies that loadCoupons properly relays Networking Layer errors.
    ///
    func test_loadCoupons_properly_relays_networking_errors() throws {
        // Given
        let remote = CouponsRemote(network: network)

        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "coupons", error: error)

        // When
        let result = waitFor { promise in
            remote.loadCoupons(for: self.sampleSiteID,
                               by: [1, 2, 3, 4]) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let resultError = try XCTUnwrap(result.failure as? NetworkError)
        XCTAssertEqual(resultError, .unacceptableStatusCode(statusCode: 500))
    }

    // MARK: - Search coupons

    /// Verifies that searchCoupons properly parses the `coupons-all` sample response.
    ///
    func test_searchCoupons_properly_returns_parsed_coupons() throws {
        // Given
        let remote = CouponsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "coupons", filename: "coupons-all")

        // When
        let result = waitFor { promise in
            remote.searchCoupons(for: self.sampleSiteID, keyword: "test", pageNumber: 0, pageSize: 20) { (result) in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isSuccess)
        let coupons = try XCTUnwrap(result.get())
        XCTAssertEqual(coupons.count, 4)
    }

    /// Verifies that searchCoupons properly relays Networking Layer errors.
    ///
    func test_searchCoupons_properly_relays_networking_errors() throws {
        // Given
        let remote = CouponsRemote(network: network)

        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "coupons", error: error)

        // When
        let result = waitFor { promise in
            remote.searchCoupons(for: self.sampleSiteID, keyword: "test", pageNumber: 0, pageSize: 20) { (result) in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let resultError = try XCTUnwrap(result.failure as? NetworkError)
        XCTAssertEqual(resultError, .unacceptableStatusCode(statusCode: 500))
    }

    // MARK: - Retrieve coupon

    /// Verifies that retrieveCoupon properly parses the `coupon` sample response.
    ///
    func test_retrieveCoupon_properly_returns_parsed_coupon() throws {
        // Given
        let sampleCouponID: Int64 = 720
        let remote = CouponsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "coupons/\(sampleCouponID)", filename: "coupon")

        // When
        let result = waitFor { promise in
            remote.retrieveCoupon(for: self.sampleSiteID, couponID: sampleCouponID) { (result) in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isSuccess)
        let coupon = try XCTUnwrap(result.get())
        let expectedCoupon = sampleCoupon()
        XCTAssertEqual(coupon, expectedCoupon)
    }

    /// Verifies that retrieveCoupon properly relays Networking Layer errors.
    ///
    func test_retrieveCoupon_properly_relays_networking_errors() throws {
        // Given
        let sampleCouponID: Int64 = 720
        let remote = CouponsRemote(network: network)
        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "coupons/\(sampleCouponID)", error: error)

        // When
        let result = waitFor { promise in
            remote.retrieveCoupon(for: self.sampleSiteID, couponID: sampleCouponID) { (result) in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let resultError = try XCTUnwrap(result.failure as? NetworkError)
        XCTAssertEqual(resultError, .unacceptableStatusCode(statusCode: 500))
    }
}

// MARK: - Private helpers
private extension CouponsRemoteTests {
    func sampleCoupon() -> Coupon {
        Coupon(siteID: sampleSiteID,
               couponID: 720,
               code: "free shipping",
               amount: "10.00",
               dateCreated: DateFormatter.dateFromString(with: "2017-03-21T18:25:02"),
               dateModified: DateFormatter.dateFromString(with: "2017-03-21T18:25:02"),
               discountType: .fixedCart,
               description: "Coupon description",
               dateExpires: DateFormatter.dateFromString(with: "2017-03-31T15:25:02"),
               usageCount: 10,
               individualUse: true, productIds: [12893712, 12389],
               excludedProductIds: [12213],
               usageLimit: 1200,
               usageLimitPerUser: 3,
               limitUsageToXItems: 10,
               freeShipping: true,
               productCategories: [123, 435, 232],
               excludedProductCategories: [908],
               excludeSaleItems: false,
               minimumAmount: "5.00",
               maximumAmount: "500.00",
               emailRestrictions: ["*@a8c.com", "someone.else@example.com"],
               usedBy: ["someone.else@example.com", "person@a8c.com"])
    }
}
