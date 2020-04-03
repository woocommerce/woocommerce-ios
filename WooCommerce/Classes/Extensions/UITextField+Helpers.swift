import UIKit

extension UITextField {
    func applyBodyStyle() {
        adjustsFontForContentSizeCategory = true
        font = .body
        textColor = .text
    }

    func applyHeadlineStyle() {
        adjustsFontForContentSizeCategory = true
        font = .headline
        textColor = .text
    }
}
