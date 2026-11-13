import Foundation
import Testing
@testable import Networking

struct BlazeBillingSummaryMapperTests {

    @Test func map_when_response_has_debt_then_parses_debt_and_payment_links() throws {
        // Given
        let response = try #require(Loader.contentsOf("blaze-billing-summary"))

        // When
        let summary = try BlazeBillingSummaryMapper().map(response: response)

        // Then
        #expect(summary.debt == 25.05)
        let paymentLink = try #require(summary.paymentLinks.first)
        #expect(summary.paymentLinks.count == 1)
        #expect(paymentLink.amount == 25.05)
        #expect(paymentLink.url == "https://example.com/pay/826745")
        #expect(paymentLink.date == Date(timeIntervalSince1970: 1_750_291_929))
    }

    @Test func map_when_response_has_no_debt_then_debt_is_zero_and_payment_links_are_empty() throws {
        // Given
        let response = try #require(Loader.contentsOf("blaze-billing-summary-without-debt"))

        // When
        let summary = try BlazeBillingSummaryMapper().map(response: response)

        // Then
        #expect(summary.debt == 0)
        #expect(summary.paymentLinks.isEmpty)
    }
}
