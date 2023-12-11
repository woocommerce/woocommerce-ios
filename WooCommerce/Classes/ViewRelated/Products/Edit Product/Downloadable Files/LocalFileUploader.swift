import Foundation
import Yosemite

/// A simpler handler for uploading local files.
///
final class LocalFileUploader {

    private let siteID: Int64
    private let productID: Int64
    private let stores: StoresManager

    init(siteID: Int64, productID: Int64, stores: StoresManager) {
        self.siteID = siteID
        self.productID = productID
        self.stores = stores
    }

    @MainActor
    func uploadFile(url: URL) async throws -> Media {
        try await withCheckedThrowingContinuation { continuation in
            stores.dispatch(MediaAction.uploadFile(siteID: siteID, productID: productID, localURL: url, altText: nil) { result in
                switch result {
                case .success(let media):
                    continuation.resume(returning: media)
                case .failure(let error):
                    DDLogError("⛔️ Error uploading local file: \(url.absoluteString)")
                    continuation.resume(throwing: error)
                }
            })
        }
    }
}
