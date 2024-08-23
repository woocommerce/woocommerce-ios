import UIKit

extension UIColor {
    var inverted: UIColor {
        return UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                self.resolvedColor(with: .init(userInterfaceStyle: .light))
            default:
                self.resolvedColor(with: .init(userInterfaceStyle: .dark))
            }
        }
    }
}
