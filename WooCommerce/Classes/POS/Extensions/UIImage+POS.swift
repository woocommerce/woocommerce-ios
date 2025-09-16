import UIKit

/// Point of Sale specific UIImage extensions
/// Contains only the UIImage extensions needed by the POS module to minimize external dependencies
extension UIImage {

    /// App icon (iPhone size) - used in receipt eligibility banner
    ///
    static var posAppIconDefault: UIImage {
        return UIImage(named: "AppIcon60x60", in: .main, compatibleWith: nil)!
    }

    /// Card Reader Update arrow - used in reader update progress
    ///
    static var posCardReaderUpdateProgressArrow: UIImage {
        return UIImage(named: "card-reader-update-progress-arrow", in: .main, compatibleWith: nil)!
    }

    /// Card Reader Update checkmark - used in reader update progress completion
    ///
    static var posCardReaderUpdateProgressCheckmark: UIImage {
        return UIImage(named: "card-reader-update-progress-checkmark", in: .main, compatibleWith: nil)!
    }
}
