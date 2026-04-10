extension Media {
    /// Derives the media type given its MIME type or file extension, if available.
    ///
    public var mediaType: MediaType {
        if mimeType.isEmpty == false {
            return MediaType(mimeType: mimeType)
        } else if fileExtension.isEmpty == false {
            return MediaType(fileExtension: fileExtension)
        } else {
            return .other
        }
    }
}
