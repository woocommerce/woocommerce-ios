import Foundation
import UIKit
import Gridicons


/// WooCommerce UIImage Assets
///
extension UIImage {

    /// WooCommerce Styled Checkmark
    ///
    static var checkmarkImage: UIImage {
        let tintColor = StyleManager.wooCommerceBrandColor
        return Gridicon.iconOfType(.checkmark).imageWithTintColor(tintColor)!
    }

    /// Gravatar Placeholder Image
    ///
    static var gravatarPlaceholderImage: UIImage {
        return UIImage(named: "gravatar")!
    }

    /// Jetpack Logo Image
    ///
    static var jetpackLogoImage: UIImage {
        return UIImage(named: "icon-jetpack-gray")!
    }
}
