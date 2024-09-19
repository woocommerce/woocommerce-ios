import XCTest
import Networking

/// Mock for `MetaDataRemote`.
///
final class MockMetaDataRemote {
    private var updatingMetaDataResult: Result<[MetaData], Error>?

    func whenUpdatingMetaData(thenReturn result: Result<[MetaData], Error>) {
        updatingMetaDataResult = result
    }
}

extension MockMetaDataRemote: MetaDataRemoteProtocol {
    func updateMetaData(for siteID: Int64, for parentID: Int64, type: MetaDataType, metadata: [[String: Any]]) async throws -> [MetaData] {
        guard let result = updatingMetaDataResult else {
            XCTFail("Could not find result for updating metadata.")
            throw NetworkError.notFound()
        }
        switch result {
        case .success(let metaData):
            return metaData
        case .failure(let error):
            throw error
        }
    }
}
