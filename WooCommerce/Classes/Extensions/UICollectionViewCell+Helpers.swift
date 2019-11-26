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
        backgroundColor = StyleManager.wooWhite
    }
    
    func applyGrayBackgroundStyle() {
        backgroundColor = StyleManager.wooGreyLight
    }
}
