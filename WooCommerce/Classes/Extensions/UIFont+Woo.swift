import Foundation
import UIKit


/// WooCommerce UIFont Helpers
///
extension UIFont {

    /// Returns the receiver *Bold* version.
    ///
    var bold: UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) else {
            DDLogError("# Error: Cannot toggle font to Bold: [\(self)]")
            return self
        }

        return UIFont(descriptor: descriptor, size: pointSize)
    }

    /// Returns the receiver *Italics* version.
    ///
    var italics: UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(.traitItalic) else {
            DDLogError("# Error: Cannot toggle font to Italics: [\(self)]")
            return self
        }

        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
