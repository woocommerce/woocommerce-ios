import Foundation
import UIKit


/// UICollectionViewCell Helpers
///
extension UICollectionViewCell {

    /// Returns a reuseIdentifier that matches the receiver's classname (non namespaced).
    ///
    class var reuseIdentifier: String {
        return classNameWithoutNamespaces
    }

    /// Applies the default background color
    ///
    func applyDefaultBackgroundStyle() {
        backgroundColor = .listForeground(modal: false)
        contentView.backgroundColor = .listForeground(modal: false)
    }

    func applyGrayBackgroundStyle() {
        backgroundColor = .systemColor(.secondarySystemGroupedBackground)
    }

    func applyContentBorderColorOnInterfaceStyleChange(borderColor: @escaping () -> UIColor) {
        let traits: [UITrait] = [
            UITraitUserInterfaceStyle.self,
            UITraitAccessibilityContrast.self
        ]
        registerForTraitChanges(traits) { (self: Self, _: UITraitCollection) in
            self.contentView.layer.borderColor = borderColor().cgColor
        }
    }
}
