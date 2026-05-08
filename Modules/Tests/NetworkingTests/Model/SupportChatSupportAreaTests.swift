import Foundation
import Testing
@testable import Networking

struct SupportChatSupportAreaTests {

    // MARK: - SupportAreaConfidence

    @Test(arguments: [
        ("high", SupportAreaConfidence.high),
        ("HIGH", SupportAreaConfidence.high),
        ("medium", SupportAreaConfidence.medium),
        ("Medium", SupportAreaConfidence.medium),
        ("low", SupportAreaConfidence.low),
        ("LOW", SupportAreaConfidence.low)
    ])
    func confidence_decodes_case_insensitively(rawValue: String, expected: SupportAreaConfidence) throws {
        // Given
        let json = "\"\(rawValue)\""
        let data = try #require(json.data(using: .utf8))

        // When
        let result = try JSONDecoder().decode(SupportAreaConfidence.self, from: data)

        // Then
        #expect(result == expected)
    }

    @Test func confidence_defaults_to_low_for_unknown_value() throws {
        // Given
        let json = "\"unknown_confidence\""
        let data = try #require(json.data(using: .utf8))

        // When
        let result = try JSONDecoder().decode(SupportAreaConfidence.self, from: data)

        // Then
        #expect(result == .low)
    }

    // MARK: - SupportAreaType

    @Test(arguments: [
        ("mobile-app", SupportAreaType.mobileApp),
        ("card-reader", SupportAreaType.cardReader),
        ("woopayments", SupportAreaType.wooPayments),
        ("woocommerce-plugin", SupportAreaType.wooCommercePlugin),
        ("other-extension-plugin", SupportAreaType.otherExtensionPlugin)
    ])
    func areaType_decodes_known_values(rawValue: String, expected: SupportAreaType) throws {
        // Given
        let json = "\"\(rawValue)\""
        let data = try #require(json.data(using: .utf8))

        // When
        let result = try JSONDecoder().decode(SupportAreaType.self, from: data)

        // Then
        #expect(result == expected)
    }

    @Test func areaType_defaults_to_mobileApp_for_unknown_value() throws {
        // Given
        let json = "\"unknown_area\""
        let data = try #require(json.data(using: .utf8))

        // When
        let result = try JSONDecoder().decode(SupportAreaType.self, from: data)

        // Then
        #expect(result == .mobileApp)
    }

    // MARK: - SupportChatSupportArea

    @Test func supportArea_isHighConfidence_returns_true_when_confidence_is_high() {
        // Given
        let supportArea = SupportChatSupportArea(area: .mobileApp, confidence: .high)

        // Then
        #expect(supportArea.isHighConfidence == true)
    }

    @Test(arguments: [SupportAreaConfidence.medium, SupportAreaConfidence.low])
    func supportArea_isHighConfidence_returns_false_when_confidence_is_not_high(confidence: SupportAreaConfidence) {
        // Given
        let supportArea = SupportChatSupportArea(area: .mobileApp, confidence: confidence)

        // Then
        #expect(supportArea.isHighConfidence == false)
    }

    @Test func supportArea_decodes_from_json() throws {
        // Given
        let json = """
        {
            "area": "woopayments",
            "confidence": "medium"
        }
        """
        let data = try #require(json.data(using: .utf8))

        // When
        let result = try JSONDecoder().decode(SupportChatSupportArea.self, from: data)

        // Then
        #expect(result.area == .wooPayments)
        #expect(result.confidence == .medium)
        #expect(result.isHighConfidence == false)
    }
}
