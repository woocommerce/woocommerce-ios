import XCTest
@testable import Networking

final class KeyedDecodingContainer_WooTests: XCTestCase {
    func test_failsafeDecodeIfPresent_string_supports_alternative_types() throws {
        let data = """
                {
                    "string": "woo",
                    "integer": 8,
                    "double": 6.8
                }
                """
            .data(using: .utf8)!

        // When
        let stringConvertible = try JSONDecoder().decode(StringConvertible.self, from: data)

        // Then
        XCTAssertEqual(stringConvertible.fromString, "woo")
        XCTAssertEqual(stringConvertible.fromInteger, "8")
        XCTAssertEqual(stringConvertible.fromDouble, "6.8")
    }
}

private extension KeyedDecodingContainer_WooTests {
    struct StringConvertible: Decodable {
        let fromString: String?
        let fromInteger: String?
        let fromDouble: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.fromString = container.failsafeDecodeIfPresent(stringForKey: .string)
            self.fromInteger = container.failsafeDecodeIfPresent(stringForKey: .integer)
            self.fromDouble = container.failsafeDecodeIfPresent(stringForKey: .double)
        }

        enum CodingKeys: String, CodingKey {
            case string
            case integer
            case double
        }
    }
}
