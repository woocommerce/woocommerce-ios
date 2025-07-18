import Foundation
import Testing
@testable import Yosemite
@testable import Networking

struct POSSiteSettingServiceTests {
    private let sut: POSSiteSettingService
    private let mockRemote: MockSiteSettingsRemote
    private let sampleSiteID: Int64 = 123

    init() {
        let mockRemote = MockSiteSettingsRemote()
        self.mockRemote = mockRemote
        self.sut = POSSiteSettingService(remote: mockRemote)
    }

    @Test(arguments: [true, false])
    func setFeature_calls_remote_with_correct_parameters(featureEnabled: Bool) async throws {
        // Given
        let feature = SiteSettingsFeature.pointOfSale
        mockRemote.setFeatureResult = .success(true)

        // When
        let result = try await sut.setFeature(siteID: sampleSiteID, feature: feature, enabled: featureEnabled)

        // Then
        #expect(mockRemote.setFeatureCalled == true)
        #expect(mockRemote.spySetFeatureSiteID == sampleSiteID)
        #expect(mockRemote.spySetFeatureFeature == feature)
        #expect(mockRemote.spySetFeatureEnabled == featureEnabled)
        #expect(result == true)
    }

    @Test(arguments: [true, false])
    func setFeature_returns_false_when_remote_returns_false(remoteFeatureEnabled: Bool) async throws {
        // Given
        let feature = SiteSettingsFeature.pointOfSale
        mockRemote.setFeatureResult = .success(remoteFeatureEnabled)

        // When
        let result = try await sut.setFeature(siteID: sampleSiteID, feature: feature, enabled: true)

        // Then
        #expect(result == remoteFeatureEnabled)
    }

    @Test func setFeature_throws_error_when_remote_throws_error() async throws {
        // Given
        let feature = SiteSettingsFeature.pointOfSale
        let expectedError = SiteSettingsRemoteError.invalidResponse
        mockRemote.setFeatureResult = .failure(expectedError)

        // When/Then
        await #expect(performing: {
            try await sut.setFeature(siteID: sampleSiteID, feature: feature, enabled: true)
        }, throws: { error in
            return error as? SiteSettingsRemoteError == expectedError
        })
    }
}
