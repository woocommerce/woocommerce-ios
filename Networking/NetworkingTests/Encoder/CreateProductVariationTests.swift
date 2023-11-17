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
        XCTAssertEqual(length["value"] as? String, "")

        let period = try XCTUnwrap(metadata.first(where: { $0["key"] as? String == "_subscription_period"}))
        XCTAssertEqual(period["value"] as? String, "day")

        let periodInterval = try XCTUnwrap(metadata.first(where: { $0["key"] as? String == "_subscription_period_interval"}))
        XCTAssertEqual(periodInterval["value"] as? String, "")

        let price = try XCTUnwrap(metadata.first(where: { $0["key"] as? String == "_subscription_price"}))
        XCTAssertEqual(price["value"] as? String, "")

        let signUpFee = try XCTUnwrap(metadata.first(where: { $0["key"] as? String == "_subscription_sign_up_fee"}))
        XCTAssertEqual(signUpFee["value"] as? String, "")

        let trialLength = try XCTUnwrap(metadata.first(where: { $0["key"] as? String == "_subscription_trial_length"}))
        XCTAssertEqual(trialLength["value"] as? String, "")

        let trialPeriod = try XCTUnwrap(metadata.first(where: { $0["key"] as? String == "_subscription_trial_period"}))
        XCTAssertEqual(trialPeriod["value"] as? String, "day")
    }

    func test_it_does_not_encode_metadata_without_subscription() throws {
        // Given
        let newVariation = CreateProductVariation.fake()

        // When
        let parameters = try newVariation.toDictionary()

        // Then
        XCTAssertNil(parameters["meta_data"])
    }

}
