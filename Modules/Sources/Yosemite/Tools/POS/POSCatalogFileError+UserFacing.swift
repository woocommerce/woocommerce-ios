import Foundation
import enum NetworkingCore.POSCatalogFileError

public extension Error {
    /// Returns `true` when the host blocks direct access to the generated POS catalog file
    /// (e.g. an Apache `.htaccess` returning 403, or an HTML error page served instead of the catalog JSON).
    var isPOSCatalogFileBlockedError: Bool {
        if case .blocked = self as? POSCatalogFileError {
            return true
        }
        return false
    }
}
