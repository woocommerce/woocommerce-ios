import UniformTypeIdentifiers

extension URL {
    var mimeTypeForPathExtension: String {
        guard
            let typeIdentifier = UTType(filenameExtension: pathExtension),
            let mimeType = typeIdentifier.preferredMIMEType else {
                return "application/octet-stream"
        }
        return mimeType
    }

    /// The expected file extension string for a given UTType identifier string.
    ///
    /// - param type: The UTType identifier string.
    /// - returns: The expected file extension or nil if unknown.
    ///
    static func fileExtensionForUTType(_ type: String) -> String? {
        return UTType(type)?.preferredFilenameExtension
    }
}
