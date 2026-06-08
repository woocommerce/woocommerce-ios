import Foundation
import enum NetworkingCore.POSCatalogFileError

public extension Error {
    /// Returns `true` when the generated POS catalog file could not be downloaded from the server.
    var isPOSCatalogFileDownloadError: Bool {
        if case .downloadFailed = self as? POSCatalogFileError {
            return true
        }
        return false
    }
}
