import Foundation
import Yosemite

/// View model for `ApplicationPasswordAuthorizationWebViewController`.
///
final class ApplicationPasswordAuthorizationViewModel {
    private let siteURL: String
    private let stores: StoresManager

    init(siteURL: String,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteURL = siteURL
        self.stores = stores
    }

    func fetchAuthURL() async throws -> URL? {
        try await withCheckedThrowingContinuation { continuation in
            let action = WordPressSiteAction.fetchApplicationPasswordAuthorizationURL(siteURL: siteURL) { result in
                switch result {
                case .success(let url):
                    continuation.resume(returning: url)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
            stores.dispatch(action)
        }
    }
}
