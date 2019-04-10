import UIKit

extension UITextField {
    func applyBodyStyle() {
        adjustsFontForContentSizeCategory = true
        font = .body
        textColor = StyleManager.defaultTextColor
    }
}
