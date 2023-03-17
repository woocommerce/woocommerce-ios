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
}
