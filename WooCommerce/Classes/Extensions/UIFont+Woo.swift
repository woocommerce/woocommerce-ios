import Foundation
import UIKit


/// WooCommerce UIFont Helpers
///
extension UIFont {

    /// Returns the receiver *Bold* version.
    ///
    var bold: UIFont {
        guard let italicDescriptor = fontDescriptor.withSymbolicTraits(.traitBold) else {
            DDLogError("# Error: Cannot toggle font to Bold: [\(self)]")
            return self
        }

        return UIFont(descriptor: italicDescriptor, size: pointSize)
    }

    /// Returns the receiver *Italics* version.
    ///
    var italics: UIFont {
        guard let italicDescriptor = fontDescriptor.withSymbolicTraits(.traitItalic) else {
            DDLogError("# Error: Cannot toggle font to Italics: [\(self)]")
            return self
        }

        return UIFont(descriptor: italicDescriptor, size: pointSize)
    }
}
