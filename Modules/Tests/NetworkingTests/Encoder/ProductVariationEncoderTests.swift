import XCTest
@testable import Networking

final class ProductVariationEncoderTests: XCTestCase {
    func test_it_encodes_subscription_into_meta_data() throws {
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
                                               paymentSyncMonth: "01")
        let variation = ProductVariation.fake().copy(subscription: subscription)

        // When
        let parameters = try variation.toDictionary()

        // Then
        let metadata =  try XCTUnwrap(parameters["meta_data"] as? [[String: Any]])

        let length = try XCTUnwrap(metadata.first(where: { $0["key"] as? String == "_subscription_length"}))
        XCTAssertEqual(length["value"] as? String, "3")

        let period = try XCTUnwrap(metadata.first(where: { $0["key"] as? String == "_subscription_period"}))
        XCTAssertEqual(period["value"] as? String, "week")

        let periodInterval = try XCTUnwrap(metadata.first(where: { $0["key"] as? String == "_subscription_period_interval"}))
        XCTAssertEqual(periodInterval["value"] as? String, "5")

        let price = try XCTUnwrap(metadata.first(where: { $0["key"] as? String == "_subscription_price"}))
        XCTAssertEqual(price["value"] as? String, "99")

        let signUpFee = try XCTUnwrap(metadata.first(where: { $0["key"] as? String == "_subscription_sign_up_fee"}))
        XCTAssertEqual(signUpFee["value"] as? String, "25")

        let trialLength = try XCTUnwrap(metadata.first(where: { $0["key"] as? String == "_subscription_trial_length"}))
        XCTAssertEqual(trialLength["value"] as? String, "1")

        let trialPeriod = try XCTUnwrap(metadata.first(where: { $0["key"] as? String == "_subscription_trial_period"}))
        XCTAssertEqual(trialPeriod["value"] as? String, "month")

        let oneTimeShipping = try XCTUnwrap(metadata.first(where: { $0["key"] as? String == "_subscription_one_time_shipping"}))
        XCTAssertEqual(oneTimeShipping["value"] as? String, "yes")
    }

    func test_it_does_not_encode_meta_data_without_subscription() throws {
        // Given
        let variation = ProductVariation.fake()

        // When
        let parameters = try variation.toDictionary()

        // Then
        XCTAssertNil(parameters["meta_data"])
    }
}
