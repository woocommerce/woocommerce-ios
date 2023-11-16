import XCTest
@testable import Networking

final class CreateProductVariationTests: XCTestCase {

    func test_it_encodes_subscription_into_meta_data_when_subscription_is_available() throws {
        // Given
        let newVariation = CreateProductVariation.fake().copy(subscription: .fake())

        // When
        let parameters = try newVariation.toDictionary()

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
    }

    func test_it_does_not_encode_metadata_without_subscription() throws {
        // Given
        let newVariation = CreateProductVariation.fake().copy(subscription: .fake())

        // When
        let parameters = try newVariation.toDictionary()

        // Then
        XCTAssertNil(parameters["meta_data"])
    }

}
