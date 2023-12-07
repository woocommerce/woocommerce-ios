import XCTest
@testable import Networking
import TestKit

final class JustInTimeMessageListMapperTests: XCTestCase {
    /// Dummy Site ID.
    ///
    private let dummySiteID: Int64 = 1678

    /// Verifies that the message is parsed.
    ///
    func test_JustInTimeMessageListMapper_parses_the_JustInTimeMessage_in_response() async throws {
        let justInTimeMessages = try await mapLoadJustInTimeMessageListResponse()
        XCTAssertNotNil(justInTimeMessages)
        assertEqual(1, justInTimeMessages.count)
    }

    /// Verifies that the message is parsed.
    ///
    func test_JustInTimeMessageListMapper_parses_the_JustInTimeMessage_in_response_without_data_envelope() async throws {
        let justInTimeMessages = try await mapLoadJustInTimeMessageListResponseWithoutDataEnvelope()
        XCTAssertNotNil(justInTimeMessages)
        assertEqual(1, justInTimeMessages.count)
    }

    /// Verifies that the fields are all parsed correctly.
    ///
    func test_JustInTimeMessageListMapper_parses_all_fields_in_result() async throws {
        // Given, When
        let justInTimeMessage = try await mapLoadJustInTimeMessageListResponse().first

        // Then
        let expectedJustInTimeMessage = JustInTimeMessage(
            siteID: dummySiteID,
            messageID: "woomobile_ipp_barcode_users",
            featureClass: "woomobile_ipp",
            content: JustInTimeMessage.Content(
                message: "In-person card payments",
                description: "Sell anywhere, and take card payments using a mobile card reader."),
            cta: JustInTimeMessage.CTA(
                message: "Purchase Card Reader",
                link: "https://woo.com/products/hardware/US"),
            assets: ["background_image_url": URL(string: "https://example.net/images/background-light@2x.png")!],
            template: "modal")
        assertEqual(expectedJustInTimeMessage, justInTimeMessage)
    }

    /// Verifies that the fields are all parsed correctly.
    ///
    func test_JustInTimeMessageListMapper_parses_correctly_when_nonessential_keys_are_missing() async throws {
        // Given, When
        let justInTimeMessage = try await mapLoadJustInTimeMessageListWithoutNonessentialKeysResponse().first

        // Then
        let expectedJustInTimeMessage = JustInTimeMessage(siteID: dummySiteID,
                                                          messageID: "woomobile_ipp_barcode_users",
                                                          featureClass: "woomobile_ipp",
                                                          content: JustInTimeMessage.Content(
                                                            message: "In-person card payments",
                                                            description: "Sell anywhere, and take card payments using a mobile card reader."),
                                                          cta: JustInTimeMessage.CTA(
                                                            message: "Purchase Card Reader",
                                                            link: "https://woo.com/products/hardware/US"),
                                                          assets: [:],
                                                          template: "default")
        assertEqual(expectedJustInTimeMessage, justInTimeMessage)
    }
}


// MARK: - Test Helpers

private extension JustInTimeMessageListMapperTests {
    /// Returns the JustInTimeMessageMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapJustInTimeMessageList(from filename: String) async throws -> [JustInTimeMessage] {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        return try await JustInTimeMessageListMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the JustInTimeMessageListMapper output from `just-in-time-message-list.json`
    ///
    func mapLoadJustInTimeMessageListResponse() async throws -> [JustInTimeMessage] {
        return try await mapJustInTimeMessageList(from: "just-in-time-message-list")
    }

    func mapLoadJustInTimeMessageListWithoutNonessentialKeysResponse() async throws -> [JustInTimeMessage] {
        return try await mapJustInTimeMessageList(from: "just-in-time-message-list-without-nonessential-keys")
    }

    /// Returns the JustInTimeMessageListMapper output from `just-in-time-message-list-without-data.json`
    ///
    func mapLoadJustInTimeMessageListResponseWithoutDataEnvelope() async throws -> [JustInTimeMessage] {
        return try await mapJustInTimeMessageList(from: "just-in-time-message-list-without-data")
    }

    struct FileNotFoundError: Error {}
}
