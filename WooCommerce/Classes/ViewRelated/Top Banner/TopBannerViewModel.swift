import UIKit

struct TopBannerViewModel {
    let title: String?
    let infoText: String?
    let icon: UIImage
    let actionButtonTitle: String
    let actionHandler: () -> Void
    let dismissHandler: () -> Void
}
