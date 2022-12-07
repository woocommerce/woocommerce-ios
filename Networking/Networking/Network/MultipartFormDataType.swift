import Foundation
import UniformTypeIdentifiers

/// Constructs `multipart/form-data` for uploads within an HTTP or HTTPS body.
///
public protocol MultipartFormDataType {
    /// Appends a file with file URL for a name to form data.
    ///
    func append(_ fileURL: URL, withName name: String, fileName: String, mimeType: String)

    /// Appends data for a name to form data.
    ///
    func append(_ data: Data, withName name: String)
}
