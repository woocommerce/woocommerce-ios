import Networking
import XCTest

/// Mock for `GenerativeContentRemote`.
///
final class MockGenerativeContentRemote {
    private(set) var generateTextBase: String?

    /// The results to return in `generateText`.
    private var generateTextResult: Result<String, Error>?

    /// Returns the value when `generateText` is called.
    func whenGeneratingText(thenReturn result: Result<String, Error>) {
        generateTextResult = result
    }
}

extension MockGenerativeContentRemote: GenerativeContentRemoteProtocol {
    func generateText(siteID: Int64, base: String) async throws -> String {
        generateTextBase = base
        guard let result = generateTextResult else {
            XCTFail("Could not find result for generating text.")
            throw NetworkError.notFound
        }
        return try result.get()
    }
}
