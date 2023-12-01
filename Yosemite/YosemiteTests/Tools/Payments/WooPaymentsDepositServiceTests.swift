import XCTest
@testable import Yosemite
@testable import Networking

final class WooPaymentsDepositServiceTests: XCTestCase {
    var service: WooPaymentsDepositService!
    var mockNetwork: MockNetwork!

    override func setUp() {
        super.setUp()
        mockNetwork = MockNetwork()
        service = WooPaymentsDepositService(siteID: 12345, network: mockNetwork)
    }

    override func tearDown() {
        mockNetwork = nil
        service = nil
        super.tearDown()
    }

    func test_fetchDepositsOverview_returns_one_model_per_response_element() async {
        // Given
        mockNetwork.simulateResponse(requestUrlSuffix: "payments/deposits/overview-all", filename: "deposits-overview-all")

        do {
            // When
            let depositsOverviews = try await service.fetchDepositsOverview()

            // Then
            assertEqual(2, depositsOverviews.count)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_fetchDepositsOverview_returns_the_default_currency_first() async {
        // Given
        mockNetwork.simulateResponse(requestUrlSuffix: "payments/deposits/overview-all", filename: "deposits-overview-all")

        do {
            // When
            let depositsOverviews = try await service.fetchDepositsOverview()

            // Then
            assertEqual(.GBP, depositsOverviews.first?.currency)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_fetchDepositsOverview_returns_empty_array_if_default_currency_lost() async {
        // Given
        mockNetwork.simulateResponse(requestUrlSuffix: "payments/deposits/overview-all", filename: "deposits-overview-all-no-default-currency")

        do {
            // When
            let depositsOverviews = try await service.fetchDepositsOverview()

            // Then
            XCTAssert(depositsOverviews.isEmpty)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_fetchDepositsOverview_returns_valid_data_for_lowercase_currency() async {
        // Given
        // (the overview JSON specifies currency as "eur")
        mockNetwork.simulateResponse(requestUrlSuffix: "payments/deposits/overview-all", filename: "deposits-overview-all")

        do {
            // When
            let depositsOverviews = try await service.fetchDepositsOverview()

            // Then
            let euroDepositOverview = try XCTUnwrap(depositsOverviews.first(where: { $0.currency == .EUR } ))
            assertEqual(NSDecimalNumber(string: "20.18"), euroDepositOverview.pendingBalanceAmount)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_fetchDepositsOverview_returns_valid_data_for_uppercase_currency() async {
        // Given
        // (this overview JSON specifies currency as "GBP")
        mockNetwork.simulateResponse(requestUrlSuffix: "payments/deposits/overview-all", filename: "deposits-overview-all")

        do {
            // When
            let depositsOverviews = try await service.fetchDepositsOverview()

            // Then
            let euroDepositOverview = try XCTUnwrap(depositsOverviews.first(where: { $0.currency == .GBP } ))
            assertEqual(NSDecimalNumber(string: "34.54"), euroDepositOverview.pendingBalanceAmount)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testFetchDepositsOverviewError() async {
        // Given
        let mockError = DotcomError.noRestRoute
        mockNetwork.simulateError(requestUrlSuffix: "payments/deposits/overview-all", error: mockError)

        do {
            // When
            _ = try await service.fetchDepositsOverview()
            XCTFail("Expected an error, but the call succeeded.")
        } catch {
            // Then
            XCTAssertEqual(error as? DotcomError, mockError)
        }
    }
}
