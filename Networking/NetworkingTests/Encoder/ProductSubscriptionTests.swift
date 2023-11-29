import XCTest
@testable import Networking

final class ProductSubscriptionTests: XCTestCase {
    func test_it_encodes_into_expected_key_value_format() throws {
        // Given
        let subscription = ProductSubscription(length: "3",
                                               period: .week,
                                               periodInterval: "5",
                                               price: "99",
                                               signUpFee: "25",
                                               trialLength: "1",
                                               trialPeriod: .month,
                                               oneTimeShipping: true,
                                               paymentSyncDate: "7",
                                               paymentSyncMonth: "02")

        // When
        let keyValuePairs = subscription.toKeyValuePairs()

        // Then
        XCTAssertTrue(keyValuePairs.contains(.init(key: "_subscription_length", value: "3")))
        XCTAssertTrue(keyValuePairs.contains(.init(key: "_subscription_period", value: "week")))
        XCTAssertTrue(keyValuePairs.contains(.init(key: "_subscription_period_interval", value: "5")))
        XCTAssertTrue(keyValuePairs.contains(.init(key: "_subscription_price", value: "99")))
        XCTAssertTrue(keyValuePairs.contains(.init(key: "_subscription_sign_up_fee", value: "25")))
        XCTAssertTrue(keyValuePairs.contains(.init(key: "_subscription_trial_length", value: "1")))
        XCTAssertTrue(keyValuePairs.contains(.init(key: "_subscription_trial_period", value: "month")))
        XCTAssertTrue(keyValuePairs.contains(.init(key: "_subscription_one_time_shipping", value: "yes")))
    }
}
