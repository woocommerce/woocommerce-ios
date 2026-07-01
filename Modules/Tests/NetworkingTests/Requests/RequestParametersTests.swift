import Foundation
import Testing
@testable import NetworkingCore

struct RequestParametersTests {
    @Test func test_dictionary_when_source_contains_mutable_values_then_snapshots_values() throws {
        // Given
        let nestedDictionary = NSMutableDictionary(dictionary: ["name": "original"])
        let nestedArray = NSMutableArray(array: ["first", nestedDictionary])
        let source = NSDictionary(dictionary: [
            "dictionary": nestedDictionary,
            "array": nestedArray
        ])

        // When
        let parameters = RequestParameters(try source.requestParameterDictionaryFromJSONObject())
        nestedDictionary["name"] = "mutated"
        nestedArray.add("second")

        // Then
        #expect(parameters.dictionary?["dictionary"] == .dictionary(["name": .string("original")]))
        #expect(parameters.dictionary?["array"] == .array([
            .string("first"),
            .dictionary(["name": .string("original")])
        ]))
    }

    @Test func test_dictionary_when_source_contains_nil_optional_then_converts_to_null() throws {
        // Given
        let value: String? = nil

        // When
        let parameters = RequestParameters(["value": value])

        // Then
        #expect(parameters.dictionary?["value"] == .null)
        let validatedValue = try #require(parameters.validatedDictionary()?["value"])
        #expect(validatedValue is NSNull)
    }

    @Test func test_requestParameterValue_when_dictionary_literal_contains_convertible_values_then_converts_nested_values() {
        // Given
        let enabled = true
        let label = "priority"

        // When
        let value: RequestParameterValue = [
            "enabled": true,
            "label": label,
            "nested": [
                "enabled": enabled
            ]
        ]

        // Then
        #expect(value == .dictionary([
            "enabled": .bool(true),
            "label": .string("priority"),
            "nested": .dictionary([
                "enabled": .bool(true)
            ])
        ]))
    }

    @Test func test_dictionary_when_source_contains_convertible_values_then_converts_values() {
        // Given
        let labels = ["shipping", "priority"]
        let label = "priority"

        // When
        let value = RequestParameterValue.dictionary([
            "enabled": true,
            "labels": labels,
            "label": label
        ])

        // Then
        #expect(value == .dictionary([
            "enabled": .bool(true),
            "labels": .array([
                .string("shipping"),
                .string("priority")
            ]),
            "label": .string("priority")
        ]))
    }

    @Test func test_array_when_source_contains_convertible_values_then_converts_values() {
        // Given
        let labels: [RequestParameterDictionary] = [
            ["label": .string("priority")],
            ["label": .string("shipping")]
        ]

        // When
        let value = RequestParameterValue.array(labels)

        // Then
        #expect(value == .array([
            .dictionary(["label": .string("priority")]),
            .dictionary(["label": .string("shipping")])
        ]))
    }

    @Test func test_requestParameterDictionaryFromJSONObject_when_source_contains_json_numbers_then_preserves_numbers() throws {
        // Given
        let data = try #require("""
        {
            "zero": 0,
            "one": 1,
            "two": 2,
            "enabled": true,
            "disabled": false
        }
        """.data(using: .utf8))
        let source = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        // When
        let parameters = try source.requestParameterDictionaryFromJSONObject()

        // Then
        #expect(parameters["zero"] == .int(0))
        #expect(parameters["one"] == .int(1))
        #expect(parameters["two"] == .int(2))
        #expect(parameters["enabled"] == .bool(true))
        #expect(parameters["disabled"] == .bool(false))
    }

    @Test func test_requestParameterDictionaryFromJSONObject_when_source_contains_nested_json_numbers_then_preserves_numbers() throws {
        // Given
        let data = try #require("""
        {
            "line_items": [
                {
                    "id": 0,
                    "product_id": 5,
                    "quantity": 1
                }
            ],
            "meta_data": [
                {
                    "id": 0,
                    "key": "_wc_order_attribution_source_type",
                    "value": "mobile_app"
                }
            ]
        }
        """.data(using: .utf8))
        let source = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])

        // When
        let parameters = try source.requestParameterDictionaryFromJSONObject()

        // Then
        #expect(parameters["line_items"] == .array([
            .dictionary([
                "id": .int(0),
                "product_id": .int(5),
                "quantity": .int(1)
            ])
        ]))
        #expect(parameters["meta_data"] == .array([
            .dictionary([
                "id": .int(0),
                "key": .string("_wc_order_attribution_source_type"),
                "value": .string("mobile_app")
            ])
        ]))
    }

    @Test func test_requestParameterDictionaryFromJSONObject_when_source_contains_unsupported_value_then_throws_error() {
        // Given
        let source = NSDictionary(dictionary: ["value": URL(string: "https://woocommerce.com")!])

        // Then
        #expect(throws: RequestParameterJSONError.unsupportedValue(type: "NSURL")) {
            try source.requestParameterDictionaryFromJSONObject()
        }
    }

    @Test func test_validatedDictionary_when_source_contains_non_finite_number_then_throws_error() {
        // Given
        let parameters = RequestParameters(["value": Double.nan])

        // Then
        #expect(throws: RequestParameterError.nonFiniteNumber(path: "parameters.value")) {
            try parameters.validatedDictionary()
        }
    }

    @Test func test_validatedDictionary_when_source_contains_non_finite_decimal_then_throws_error() {
        // Given
        let parameters = RequestParameters(["value": Decimal.nan])

        // Then
        #expect(throws: RequestParameterError.nonFiniteNumber(path: "parameters.value")) {
            try parameters.validatedDictionary()
        }
    }
}
