@testable import Yosemite

// MARK: - Equatable Conformance
//
extension Media: Equatable {
    public static func == (lhs: Media, rhs: Media) -> Bool {
        return lhs.mediaID == rhs.mediaID &&
            lhs.date == rhs.date &&
            lhs.fileExtension == rhs.fileExtension &&
            lhs.mimeType == rhs.mimeType &&
            lhs.src == rhs.src &&
            lhs.thumbnailURL == rhs.thumbnailURL &&
            lhs.name == rhs.name &&
            lhs.alt == rhs.alt &&
            lhs.height == rhs.height &&
            lhs.width == rhs.width
    }
}
