import XCTest
import TestKit
@testable import Networking

final class PaymentRemoteTests: XCTestCase {
    /// Mock network wrapper.
    private var network: MockNetwork!

    override func setUp() {
        super.setUp()
        network = MockNetwork()
    }

    override func tearDown() {
        network = nil
        super.tearDown()
    }

    // MARK: - `loadPlan`

    func test_loadPlan_returns_plan_on_success() async throws {
        // Given
        let remote = PaymentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "plans", filename: "load-plan-success")

        // When
        let plan = try await remote.loadPlan(thatMatchesID: Constants.planProductID)

        // Then
        XCTAssertEqual(plan, .init(productID: Constants.planProductID,
                                   name: "WordPress.com eCommerce",
                                   formattedPrice: "NT$2,230"))
    }

    func test_loadPlan_throws_noMatchingPlan_error_when_response_does_not_include_plan_with_given_id() async throws {
        // Given
        let remote = PaymentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "plans", filename: "load-plan-success")

        // When
        await assertThrowsError {
            _ = try await remote.loadPlan(thatMatchesID: 9)
        } errorAssert: { error in
            // Then
            (error as? LoadPlanError) == .noMatchingPlan
        }
    }

    func test_loadPlan_throws_notFound_error_when_no_response() async throws {
        // Given
        let remote = PaymentRemote(network: network)

        // When
        await assertThrowsError {
            _ = try await remote.loadPlan(thatMatchesID: 9)
        } errorAssert: { error in
            // Then
            (error as? NetworkError) == .notFound
        }
    }

    // MARK: - `loadSiteCurrentPlan`

    func test_loadSiteCurrentPlan_returns_site_plan_on_success() async throws {
        // Given
        let remote = PaymentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "plans", filename: "load-site-current-plan-success")

        // When
        let plan = try await remote.loadSiteCurrentPlan(siteID: 134)

        // Then
        XCTAssertEqual(plan, .init(hasDomainCredit: false))
    }

    func test_loadSiteCurrentPlan_returns_noCurrentPlan_error_when_response_has_no_current_plan() async throws {
        // Given
        let remote = PaymentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "plans", filename: "load-site-plans-no-current-plan")

        // When
        await assertThrowsError {
            _ = try await remote.loadSiteCurrentPlan(siteID: 6)
        } errorAssert: { error in
            // Then
            (error as? LoadSiteCurrentPlanError) == LoadSiteCurrentPlanError.noCurrentPlan
        }
    }

    func test_loadSiteCurrentPlan_throws_notFound_error_when_no_response() async throws {
        // Given
        let remote = PaymentRemote(network: network)

        // When
        await assertThrowsError {
            _ = try await remote.loadSiteCurrentPlan(siteID: 6)
        } errorAssert: { error in
            // Then
            (error as? NetworkError) == .notFound
        }
    }

    // MARK: - `createCart`

    func test_createCart_returns_on_success() async throws {
        // Given
        let siteID: Int64 = 606
        let remote = PaymentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "me/shopping-cart/\(siteID)", filename: "create-cart-success")

        // When
        do {
            try await remote.createCart(siteID: siteID, productID: Constants.planProductID)
        } catch {
            // Then
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_createCart_throws_productNotInCart_error_when_response_does_not_include_plan_with_given_id() async throws {
        // Given
        let siteID: Int64 = 606
        let remote = PaymentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "me/shopping-cart/\(siteID)", filename: "create-cart-success")

        // When
        await assertThrowsError {
            _ = try await remote.createCart(siteID: siteID, productID: 685)
        } errorAssert: { error in
            // Then
            (error as? CreateCartError) == .productNotInCart
        }
    }

    func test_createCart_throws_notFound_error_when_no_response() async throws {
        // Given
        let remote = PaymentRemote(network: network)

        // When
        await assertThrowsError {
            _ = try await remote.createCart(siteID: 606, productID: 685)
        } errorAssert: { error in
            // Then
            (error as? NetworkError) == .notFound
        }
    }

    // MARK: - `createCart` with a domain

    func test_createCartWithDomain_returns_on_success() async throws {
        // Given
        let siteID: Int64 = 606
        let remote = PaymentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "me/shopping-cart/\(siteID)", filename: "create-doman-cart-success")

        // When
        do {
            let response = try await remote.createCart(siteID: siteID,
                                                       domain: .init(name: "fun.toys", productID: 254, supportsPrivacy: true),
                                                       isTemporary: false)
            // Then
            XCTAssertFalse(response.values.isEmpty)
        } catch {
            // Then
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_createCartWithDomain_throws_productNotInCart_error_when_response_does_not_include_domain_product_id() async throws {
        // Given
        let siteID: Int64 = 606
        let remote = PaymentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "me/shopping-cart/\(siteID)", filename: "create-doman-cart-success")

        // When
        await assertThrowsError {
            _ = try await remote.createCart(siteID: siteID, domain: .init(name: "fun.toys", productID: 685, supportsPrivacy: true), isTemporary: false)
        } errorAssert: { error in
            // Then
            (error as? CreateCartError) == .productNotInCart
        }
    }

    func test_createCartWithDomain_throws_notFound_error_when_no_response() async throws {
        // Given
        let remote = PaymentRemote(network: network)

        // When
        await assertThrowsError {
            _ = try await remote.createCart(siteID: 606, domain: .init(name: "fun.toys", productID: 254, supportsPrivacy: true), isTemporary: false)
        } errorAssert: { error in
            // Then
            (error as? NetworkError) == .notFound
        }
    }

    // MARK: - `checkoutCartWithDomainCredit` with a domain

    func test_checkoutCartWithDomainCredit_returns_on_success() async throws {
        // Given
        let remote = PaymentRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "me/transactions", filename: "checkout-doman-cart-with-domain-credit-success")

        // When
        do {
            try await remote.checkoutCartWithDomainCredit(cart: [:])
        } catch {
            // Then
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_checkoutCartWithDomainCredit_throws_notFound_error_when_no_response() async throws {
        // Given
        let remote = PaymentRemote(network: network)

        // When
        await assertThrowsError {
            try await remote.checkoutCartWithDomainCredit(cart: [:])
        } errorAssert: { error in
            // Then
            (error as? NetworkError) == .notFound
        }
    }
}

private extension PaymentRemoteTests {
    enum Constants {
        static let planProductID: Int64 = 1021
    }
}
