import UIKit

extension UIButton {
    func applyFilledRoundStyle() {
        layer.borderColor = StyleManager.wooCommerceBrandColor.cgColor
        backgroundColor = StyleManager.wooCommerceBrandColor
        tintColor = .white
        layer.cornerRadius = 8.0
    }
}
