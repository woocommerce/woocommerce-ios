import UIKit

extension UITextField {
    func applyBodyStyle() {
        adjustsFontForContentSizeCategory = true
        font = .body
        textColor = .text
    }

    func applySecondaryBodyStyle() {
        adjustsFontForContentSizeCategory = true
        font = .body
        textColor = .textSubtle
    }

    func applyHeadlineStyle() {
        adjustsFontForContentSizeCategory = true
        font = .headline
        textColor = .text
    }
}
