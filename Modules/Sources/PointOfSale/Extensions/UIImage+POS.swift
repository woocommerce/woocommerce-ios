import UIKit

/// Point of Sale specific UIImage extensions
/// Contains only the UIImage extensions needed by the POS module to minimize external dependencies
extension UIImage {

    /// App icon (iPhone size) - used in receipt eligibility banner
    ///
    static var appIconDefault: UIImage {
        return UIImage(named: "AppIcon60x60")!
    }

    /// Card Reader Update arrow - used in reader update progress
    ///
    static var cardReaderUpdateProgressArrow: UIImage {
        return UIImage(named: "card-reader-update-progress-arrow")!
    }

    /// Card Reader Update checkmark - used in reader update progress completion
    ///
    static var cardReaderUpdateProgressCheckmark: UIImage {
        return UIImage(named: "card-reader-update-progress-checkmark")!
    }
}
