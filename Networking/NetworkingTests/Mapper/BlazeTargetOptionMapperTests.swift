import XCTest
@testable import Networking

final class BlazeTargetOptionMapperTests: XCTestCase {
    /// Verifies that the language list is parsed.
    ///
    func test_BlazeTargetLanguageListMapper_parses_all_contents_in_response() throws {
        // When
        let list = try XCTUnwrap(mapLoadBlazeTargetLanguageResponse())

        // Then
        XCTAssertEqual(list, [
            .init(id: "en", name: "English"),
            .init(id: "es", name: "Spanish")
        ])
    }

    /// Verifies that the device list is parsed.
    ///
    func test_BlazeTargetDeviceListMapper_parses_all_contents_in_response() throws {
        // When
        let list = try XCTUnwrap(mapLoadBlazeTargetDeviceResponse())

        // Then
        XCTAssertEqual(list, [
            .init(id: "mobile", name: "Mobile"),
            .init(id: "desktop", name: "Desktop")
        ])
    }

    /// Verifies that the topic list is parsed.
    ///
    func test_BlazeTargetTopicListMapper_parses_all_contents_in_response() throws {
        // When
        let list = try XCTUnwrap(mapLoadBlazeTargetTopicResponse())

        // Then
        XCTAssertEqual(list, [
            .init(id: "IAB1", description: "Arts & Entertainment"),
            .init(id: "IAB2", description: "Automotive"),
            .init(id: "IAB3", description: "Business")
        ])
    }

    /// Verifies that the location list is parsed.
    ///
    func test_BlazeTargetLocationListMapper_parses_all_contents_in_response() throws {
        // When
        let list = try XCTUnwrap(mapLoadBlazeTargetLocationResponse())

        // Then
        XCTAssertEqual(list.count, 3)
        let firstItem = try XCTUnwrap(list.first)
        XCTAssertEqual(firstItem.id, 1439)
        XCTAssertEqual(firstItem.name, "Madrid")
        XCTAssertEqual(firstItem.type, "state")
        XCTAssertNil(firstItem.code)
        XCTAssertNil(firstItem.isoCode)
        XCTAssertEqual(firstItem.parentLocation?.id, 69)
        XCTAssertEqual(firstItem.parentLocation?.parentLocation?.id, 228)
        XCTAssertNil(firstItem.parentLocation?.parentLocation?.parentLocation)
    }
}

private extension BlazeTargetOptionMapperTests {

    /// Returns the [BlazeTargetLanguage] output from `blaze-target-languages.json`
    ///
    func mapLoadBlazeTargetLanguageResponse() throws -> [BlazeTargetLanguage] {
        guard let response = Loader.contentsOf("blaze-target-languages") else {
            return []
        }
        return try BlazeTargetLanguageListMapper().map(response: response)
    }

    /// Returns the [BlazeTargetDevice] output from `blaze-target-devices.json`
    ///
    func mapLoadBlazeTargetDeviceResponse() throws -> [BlazeTargetDevice] {
        guard let response = Loader.contentsOf("blaze-target-devices") else {
            return []
        }
        return try BlazeTargetDeviceListMapper().map(response: response)
    }

    /// Returns the [BlazeTargetTopic] output from `blaze-target-topics.json`
    ///
    func mapLoadBlazeTargetTopicResponse() throws -> [BlazeTargetTopic] {
        guard let response = Loader.contentsOf("blaze-target-topics") else {
            return []
        }
        return try BlazeTargetTopicListMapper().map(response: response)
    }

    /// Returns the [BlazeTargetLocation] output from `blaze-target-locations.json`
    ///
    func mapLoadBlazeTargetLocationResponse() throws -> [BlazeTargetLocation] {
        guard let response = Loader.contentsOf("blaze-target-locations") else {
            return []
        }
        return try BlazeTargetLocationListMapper().map(response: response)
    }
}
