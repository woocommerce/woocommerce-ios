import Foundation
import Storage


// MARK: - Storage.ProductDownload: ReadOnlyConvertible
//
extension Storage.ProductDownload: ReadOnlyConvertible {

    /// Updates the Storage.ProductAttribute with the ReadOnly.
    ///
    public func update(with image: Yosemite.ProductDownload) {
        downloadID = image.downloadID
        name = image.name
        fileURL = image.fileURL
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductDownload {
        return ProductDownload(downloadID: downloadID,
                               name: name ?? "",
                               fileURL: fileURL ?? "")
    }
}
