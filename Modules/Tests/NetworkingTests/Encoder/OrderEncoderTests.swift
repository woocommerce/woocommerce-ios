import XCTest
@testable import Networking

final class OrderEncoderTests: XCTestCase {
    func test_OrderItemBundleItem_isOptionalAndSelected_is_encoded_to_a_placeholder_string_when_false() throws {
        // Given
        let order = Order.fake().copy(items: [
            .fake().copy(bundleConfiguration: [
                .fake().copy(isOptionalAndSelected: false)
            ])
        ])

        // When
        let parameters = try order.items.map { try $0.toDictionary() }

        // Then
        let bundleConfiguration = try XCTUnwrap((parameters.first?["bundle_configuration"] as? [[String: Any]])?.first)
        XCTAssertEqual(bundleConfiguration["optional_selected"] as? String, "no")
    }

    func test_OrderItemBundleItem_isOptionalAndSelected_is_encoded_to_a_true_boolean_when_true() throws {
        // Given
        let order = Order.fake().copy(items: [
            .fake().copy(bundleConfiguration: [
                .fake().copy(isOptionalAndSelected: true)
            ])
        ])

        // When
        let parameters = try order.items.map { try $0.toDictionary() }

        // Then
        let bundleConfiguration = try XCTUnwrap((parameters.first?["bundle_configuration"] as? [[String: Any]])?.first)
        XCTAssertEqual(bundleConfiguration["optional_selected"] as? Bool, true)
    }
}
