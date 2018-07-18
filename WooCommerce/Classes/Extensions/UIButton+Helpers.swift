import UIKit

extension UIButton {
    func wooPrimaryButton() {
        layer.borderColor = StyleManager.wooCommerceBrandColor.cgColor
        backgroundColor = StyleManager.wooCommerceBrandColor
        tintColor = .white
        layer.cornerRadius = 8.0
        contentEdgeInsets = UIEdgeInsetsMake(16.0, 16.0, 16.0, 16.0)
        titleLabel?.applyTitleStyle()
    }
}
