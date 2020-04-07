@testable import Yosemite

// MARK: - Equatable Override
//
extension Media {
    public override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? Media else {
            return false
        }

        return mediaID == object.mediaID &&
            date == object.date &&
            fileExtension == object.fileExtension &&
            mimeType == object.mimeType &&
            src == object.src &&
            thumbnailURL == object.thumbnailURL &&
            name == object.name &&
            alt == object.alt &&
            height == object.height &&
            width == object.width
    }
}
