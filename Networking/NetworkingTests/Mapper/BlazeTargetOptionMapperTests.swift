import XCTest
@testable import Networking

final class BlazeTargetOptionMapperTests: XCTestCase {
    /// Verifies that the language list is parsed.
    ///
    func test_BlazeTargetLanguageListMapper_parses_all_contents_in_response() throws {
        // When
        let list = try XCTUnwrap(mapLoadBlazeTargetLanguageResponse(locale: "vi"))

        // Then
        XCTAssertEqual(list, [
            .init(id: "en", name: "English", locale: "vi"),
            .init(id: "es", name: "Spanish", locale: "vi")
        ])
    }

    /// Verifies that the device list is parsed.
    ///
    func test_BlazeTargetDeviceListMapper_parses_all_contents_in_response() throws {
        // When
        let list = try XCTUnwrap(mapLoadBlazeTargetDeviceResponse(locale: "vi"))

        // Then
        XCTAssertEqual(list, [
            .init(id: "mobile", name: "Mobile", locale: "vi"),
            .init(id: "desktop", name: "Desktop", locale: "vi")
        ])
    }

    /// Verifies that the topic list is parsed.
    ///
    func test_BlazeTargetTopicListMapper_parses_all_contents_in_response() throws {
        // When
        let list = try XCTUnwrap(mapLoadBlazeTargetTopicResponse(locale: "vi"))

        // Then
        XCTAssertEqual(list, [
            .init(id: "IAB1", name: "Arts & Entertainment", locale: "vi"),
            .init(id: "IAB2", name: "Automotive", locale: "vi"),
            .init(id: "IAB3", name: "Business", locale: "vi")
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
        XCTAssertEqual(firstItem.parentLocation?.id, 69)
        XCTAssertEqual(firstItem.parentLocation?.parentLocation?.id, 228)
        XCTAssertEqual(firstItem.parentLocation?.parentLocation?.parentLocation?.id, 5)
        XCTAssertNil(firstItem.parentLocation?.parentLocation?.parentLocation?.parentLocation)
        XCTAssertEqual(firstItem.allParentLocationNames, ["Comunidad De Madrid", "Spain", "Europe"])
    }
}

private extension BlazeTargetOptionMapperTests {

    /// Returns the [BlazeTargetLanguage] output from `blaze-target-languages.json`
    ///
    func mapLoadBlazeTargetLanguageResponse(locale: String) throws -> [BlazeTargetLanguage] {
        guard let response = Loader.contentsOf("blaze-target-languages") else {
            return []
        }
        return try BlazeTargetLanguageListMapper(locale: locale).map(response: response)
    }

    /// Returns the [BlazeTargetDevice] output from `blaze-target-devices.json`
    ///
    func mapLoadBlazeTargetDeviceResponse(locale: String) throws -> [BlazeTargetDevice] {
        guard let response = Loader.contentsOf("blaze-target-devices") else {
            return []
        }
        return try BlazeTargetDeviceListMapper(locale: locale).map(response: response)
    }

    /// Returns the [BlazeTargetTopic] output from `blaze-target-topics.json`
    ///
    func mapLoadBlazeTargetTopicResponse(locale: String) throws -> [BlazeTargetTopic] {
        guard let response = Loader.contentsOf("blaze-target-topics") else {
            return []
        }
        return try BlazeTargetTopicListMapper(locale: locale).map(response: response)
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
