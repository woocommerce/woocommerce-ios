import Foundation


/// Represents a Product Download Entity.
///
public struct ProductDownload: Decodable {
    public let fileID: String
    public let fileName: String
    public let fileURL: String

    /// Product Download struct initializer.
    ///
    public init(fileID: String,
                fileName: String,
                fileURL: String) {
        self.fileID = fileID
        self.fileName = fileName
        self.fileURL = fileURL
    }
}


/// Defines all of the Product Download CodingKeys
///
private extension ProductDownload {
    enum CodingKeys: String, CodingKey {
        case fileID =   "id"
        case fileName = "name"
        case fileURL =  "file"
    }
}

