import XCTest
@testable import Networking

final class ProductSubscriptionEncoderTests: XCTestCase {
    func test_it_encodes_into_expected_key_value_format() throws {
        // Given
        let subscription = ProductSubscription(length: "3",
                                               period: .week,
                                               periodInterval: "5",
                                               price: "99",
                                               signUpFee: "25",
                                               trialLength: "1",
                                               trialPeriod: .month)

        // When
        let jsonEncoder = JSONEncoder()

        let data = try jsonEncoder.encode(subscription)
        let keyValueDictArray = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [[String: Any]])

        // Then
        let length = try XCTUnwrap(keyValueDictArray.first(where: { $0["key"] as? String == "_subscription_length"}))
        XCTAssertEqual(length["value"] as? String, "3")

        let period = try XCTUnwrap(keyValueDictArray.first(where: { $0["key"] as? String == "_subscription_period"}))
        XCTAssertEqual(period["value"] as? String, "week")

        let periodInterval = try XCTUnwrap(keyValueDictArray.first(where: { $0["key"] as? String == "_subscription_period_interval"}))
        XCTAssertEqual(periodInterval["value"] as? String, "5")

        let price = try XCTUnwrap(keyValueDictArray.first(where: { $0["key"] as? String == "_subscription_price"}))
        XCTAssertEqual(price["value"] as? String, "99")

        let signUpFee = try XCTUnwrap(keyValueDictArray.first(where: { $0["key"] as? String == "_subscription_sign_up_fee"}))
        XCTAssertEqual(signUpFee["value"] as? String, "25")

        let trialLength = try XCTUnwrap(keyValueDictArray.first(where: { $0["key"] as? String == "_subscription_trial_length"}))
        XCTAssertEqual(trialLength["value"] as? String, "1")

        let trialPeriod = try XCTUnwrap(keyValueDictArray.first(where: { $0["key"] as? String == "_subscription_trial_period"}))
        XCTAssertEqual(trialPeriod["value"] as? String, "month")
    }
}
