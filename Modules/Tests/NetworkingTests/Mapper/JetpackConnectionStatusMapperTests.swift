import Foundation
import Testing
@testable import Networking

@Suite("JetpackConnectionStatusMapper")
struct JetpackConnectionStatusMapperTests {

    @Test func test_offline_mode_is_parsed_as_active_when_offlineMode_isActive_is_true() throws {
        // Given
        let status = try mapStatus(from: "jetpack-connection-offline-mode")

        // Then
        #expect(status.offlineMode?.isActive == true)
        #expect(status.isInOfflineMode)
    }

    @Test func test_offline_mode_is_parsed_from_data_envelope() throws {
        // Given
        let status = try mapStatus(from: "jetpack-connection-offline-mode-enveloped")

        // Then
        #expect(status.offlineMode?.isActive == true)
        #expect(status.isInOfflineMode)
    }

    @Test func test_offline_mode_is_inactive_when_offlineMode_isActive_is_false() throws {
        // Given
        let status = try mapStatus(from: "jetpack-connection-online")

        // Then
        #expect(status.offlineMode?.isActive == false)
        #expect(status.isInOfflineMode == false)
    }

    @Test func test_offline_mode_is_inactive_when_offlineMode_is_missing() throws {
        // Given
        let response = Data(#"{"isActive": true}"#.utf8)

        // When
        let status = try JetpackConnectionStatusMapper().map(response: response)

        // Then
        #expect(status.offlineMode == nil)
        #expect(status.isInOfflineMode == false)
    }
}

private extension JetpackConnectionStatusMapperTests {
    func mapStatus(from filename: String) throws -> JetpackConnectionStatus {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }
        return try JetpackConnectionStatusMapper().map(response: response)
    }

    struct FileNotFoundError: Error {}
}
