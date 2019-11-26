import UIKit

extension UIImage {
    func applyProductFormSettingsStyle() -> UIImage {
        let color = UIColor.textSubtle
        return imageWithTintColor(color)!
    }
}
