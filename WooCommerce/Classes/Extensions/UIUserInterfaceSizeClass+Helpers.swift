import UIKit

extension UIUserInterfaceSizeClass {
    var nameForAnalytics: String {
        switch self {
        case .unspecified:
            return "unspecified"
        case .compact:
            return "compact"
        case .regular:
            return "regular"
        @unknown default:
            return "unknown"
        }
    }
}
