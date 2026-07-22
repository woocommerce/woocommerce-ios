import Foundation
import Testing
@testable import WooCommerce
import Yosemite

struct InPersonPaymentsStripeAccountPendingViewModelTests {

    @Test func message_when_a_deadline_is_known_then_includes_the_formatted_deadline() async throws {
        // Given
        let deadline = Date(timeIntervalSince1970: 1628652600) // August 11, 2021
        let sut = InPersonPaymentsStripeAccountPendingViewModel(deadline: deadline,
                                                                plugin: .wcPay,
                                                                analyticReason: "",
                                                                onSkip: {})

        // When
        let message = sut.message

        // Then
        #expect(message.contains(deadline.toString(dateStyle: .long, timeStyle: .none)))
    }

    @Test func message_when_no_deadline_is_known_then_falls_back_to_the_unknown_deadline_message() async throws {
        // Given
        let sut = InPersonPaymentsStripeAccountPendingViewModel(deadline: nil,
                                                                plugin: .wcPay,
                                                                analyticReason: "",
                                                                onSkip: {})

        // When
        let message = sut.message

        // Then
        #expect(!message.contains("%1$@"))
        #expect(message.contains("complete those requirements to keep accepting"))
    }
}
