/// Media that has the data fields to be uploaded to the WordPress Site Media
///
public struct UploadableMedia: GeneratedFakeable {
    public let localURL: URL
    public let filename: String
    public let mimeType: String

    public init(localURL: URL, filename: String, mimeType: String) {
        self.localURL = localURL
        self.filename = filename
        self.mimeType = mimeType
    }
}
