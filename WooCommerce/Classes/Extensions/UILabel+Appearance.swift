import Foundation
import UIKit


// MARK: - UILabel + Woo
//
extension UILabel {

    /// Applies the default WC's Appearance
    ///
    class func applyWooAppearance() {
        let appearanceInHeaderFooter = UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self])
        appearanceInHeaderFooter.textColor = .listIcon
    }
}
