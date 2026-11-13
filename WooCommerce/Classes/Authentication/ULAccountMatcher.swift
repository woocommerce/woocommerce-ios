import Foundation
import Yosemite
import protocol Storage.StorageManagerType

/// Used to match a site address with a wordpress.com account, as part
/// of the Unified Login process
final class ULAccountMatcher {
    private let wpComURL = "https://wordpress.com"
    /// ResultsController: Loads all Sites from the Storage Layer.
    ///
    private lazy var resultsController: ResultsController<StorageSite> = {
        let descriptor = NSSortDescriptor(key: "name", ascending: true)
        return ResultsController(storageManager: storageManager, sortedBy: [descriptor])
    }()

    private var sites: [Site] {
        resultsController.fetchedObjects
    }

    private let storageManager: StorageManagerType

    init(storageManager: StorageManagerType = ServiceLocator.storageManager) {
        self.storageManager = storageManager
    }

    /// Checks if the user has any site that has WooCommerce.
    ///
    var hasConnectedStores: Bool {
        sites.contains(where: { $0.isWooCommerceActive })
    }

    /// Checks if the URL passed as parameter is one of the sites
    /// saved in Storage
    /// - Parameter originalURL: a store address
    /// - Returns: a boolean indicating if the url passed as parameter is already saved
    func match(originalURL: String) -> Bool {

        /// When loggin in with a wp.com account, WPAuthenticator will set the
        /// account's blog URL to be `https://wordpress.com`
        /// We want to move forward and allow the login for those.
        guard originalURL != wpComURL else {
            return true
        }

        return matchedSite(originalURL: originalURL) != nil
    }

    /// Returns a locally stored site that matches the given site URL.
    /// - Parameter originalURL: a site address.
    /// - Returns: a locally stored `Site` that matches the given site URL. If there is no match, `nil` is returned.
    func matchedSite(originalURL: String) -> Site? {

        /// When logging in with a wp.com account, WPAuthenticator will set the
        /// account's blog URL to be `https://wordpress.com`
        /// We want to return `nil` in this case.
        guard originalURL != wpComURL else {
            return nil
        }

        guard let address = SiteAddress(originalURL) else { return nil }
        // Prefer the entered hostname when both variants belong to this account.
        if let exactMatch = sites.first(where: { SiteAddress($0.url) == address }) {
            return exactMatch
        }
        let candidates = sites.filter { SiteAddress($0.url)?.withoutWWW == address.withoutWWW }
        // Do not choose an arbitrary store if the fallback is ambiguous.
        return candidates.count == 1 ? candidates.first : nil
    }

    /// Refreshes locally stored sites that were synced previously.
    func refreshStoredSites() {
        do {
            try resultsController.performFetch()
        } catch {
            DDLogError("⛔️ Unable to refresh locally stored sites: \(error)")
        }
    }
}

private extension ULAccountMatcher {
    struct SiteAddress: Equatable {
        var host: String
        let port: Int?
        let path: String
        let query: String?

        init?(_ address: String) {
            let address = address.contains("://") ? address : "https://" + address
            guard let components = URLComponents(string: address),
                  ["http", "https"].contains(components.scheme?.lowercased() ?? ""),
                  let host = components.host, !host.isEmpty,
                  components.user == nil, components.password == nil else { return nil }
            self.host = host.lowercased()
            port = components.port
            path = components.percentEncodedPath.hasSuffix("/")
                ? String(components.percentEncodedPath.dropLast())
                : components.percentEncodedPath
            query = components.percentEncodedQuery
        }

        var withoutWWW: Self {
            var address = self
            if address.host.hasPrefix("www.") {
                address.host = String(address.host.dropFirst(4))
            }
            return address
        }
    }
}
