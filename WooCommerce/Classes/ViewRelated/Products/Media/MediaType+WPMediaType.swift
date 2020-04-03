import WPMediaPicker
import Yosemite

extension MediaType {
    /// Maps `MediaType` to `WPMediaType`.
    ///
    var toWPMediaType: WPMediaType {
        switch self {
        case .image:
            return .image
        case .video:
            return .video
        case .audio:
            return .audio
        default:
            return .other
        }
    }
}
