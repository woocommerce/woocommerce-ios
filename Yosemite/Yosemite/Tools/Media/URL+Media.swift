import MobileCoreServices

extension URL {
    var mimeTypeForPathExtension: String {
        if
            let id = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, lastPathComponent as CFString, nil)?.takeRetainedValue(),
            let contentType = UTTypeCopyPreferredTagWithClass(id, kUTTagClassMIMEType)?.takeRetainedValue() {
            return contentType as String
        }

        return "application/octet-stream"
    }

    /// The expected file extension string for a given UTType identifier string.
    ///
    /// - param type: The UTType identifier string.
    /// - returns: The expected file extension or nil if unknown.
    ///
    static func fileExtensionForUTType(_ type: String) -> String? {
        let fileExtension = UTTypeCopyPreferredTagWithClass(type as CFString, kUTTagClassFilenameExtension)?.takeRetainedValue()
        return fileExtension as String?
    }
}
