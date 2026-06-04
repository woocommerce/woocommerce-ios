import Foundation
import enum NetworkingCore.POSCatalogFileError

public extension Error {
    /// Returns `true` when the generated POS catalog file could not be fetched or parsed as a catalog response.
    var isPOSCatalogFileResponseError: Bool {
        self is POSCatalogFileError
    }
}
