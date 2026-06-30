import Networking
import XCTest

/// Mock for `FeatureFlagRemote`.
///
final class MockFeatureFlagRemote {
    /// The results to return in `loadAllFeatureFlags`.
    private var loadAllFeatureFlagsResult: Result<[RemoteFeatureFlag: Bool], Error>?

    /// The number of times `loadAllFeatureFlags` has been called.
    private(set) var loadAllFeatureFlagsCallCount = 0

    private(set) var activePluginVersions = [[String: String]]()

    /// Returns the value when `loadAllFeatureFlags` is called.
    func whenLoadingAllFeatureFlags(thenReturn result: Result<[RemoteFeatureFlag: Bool], Error>) {
        loadAllFeatureFlagsResult = result
    }
}

extension MockFeatureFlagRemote: FeatureFlagRemoteProtocol {
    func loadAllFeatureFlags(activePluginVersions: [String: String]) async throws -> [RemoteFeatureFlag: Bool] {
        loadAllFeatureFlagsCallCount += 1
        self.activePluginVersions.append(activePluginVersions)
        guard let result = loadAllFeatureFlagsResult else {
            XCTFail("Could not find result for loading all feature flags.")
            throw NetworkError.notFound()
        }
        return try result.get()
    }
}
