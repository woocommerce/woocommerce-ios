import UIKit

extension UIButton {
    func applyPrimaryButtonStyle() {
        layer.borderColor = StyleManager.wooCommerceBrandColor.cgColor
        backgroundColor = StyleManager.wooCommerceBrandColor
        tintColor = .white
        layer.cornerRadius = 8.0
        contentEdgeInsets = UIEdgeInsetsMake(16.0, 16.0, 16.0, 16.0)
        titleLabel?.applyHeadlineStyle()
    }
}
