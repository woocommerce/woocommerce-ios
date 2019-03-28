import Foundation
import Storage


// MARK: - Storage.ProductDimensions: ReadOnlyConvertible
//
extension Storage.ProductDimensions: ReadOnlyConvertible {

    /// Updates the Storage.ProductDimensions with the ReadOnly.
    ///
    public func update(with dimension: Yosemite.ProductDimensions) {
        length = dimension.length
        height = dimension.height
        width = dimension.width
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductDimensions {
        return ProductDimensions(length: length, width: width, height: height)
    }
}
