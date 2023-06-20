import Networking
import XCTest

/// Mock for `GenerativeContentRemote`.
///
final class MockGenerativeContentRemote {
    private(set) var generateTextBase: String?
    private(set) var generateTextFeature: GenerativeContentRemoteFeature?

    /// The results to return in `generateText`.
    private var generateTextResult: Result<String, Error>?

    /// Returns the value when `generateText` is called.
    func whenGeneratingText(thenReturn result: Result<String, Error>) {
        generateTextResult = result
    }
}

extension MockGenerativeContentRemote: GenerativeContentRemoteProtocol {
    func generateText(siteID: Int64,
                      base: String,
                      feature: GenerativeContentRemoteFeature) async throws -> String {
        generateTextBase = base
        generateTextFeature = feature
        guard let result = generateTextResult else {
            XCTFail("Could not find result for generating text.")
            throw NetworkError.notFound
        }
        return try result.get()
    }
}
