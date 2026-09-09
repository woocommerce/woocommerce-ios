import UIKit

extension UIUserInterfaceIdiom {
    var deviceTypeForAnalytics: String {
        switch self {
        case .phone:
            return "phone"
        case .pad:
            return "tablet"
        case .mac:
            return "mac"
        case .vision:
            return "vision"
        case .tv:
            return "tv"
        case .carPlay:
            return "car_play"
        case .unspecified:
            return "unspecified"
        @unknown default:
            return "unknown"
        }
    }
}
