import Foundation
import UIKit


/// EmptyStores: Displayed whenever there are no available WooCommerce Stores associated with the active account.
///
class EmptyStoresTableViewCell: UITableViewCell {

    /// UITableView's Reuse Identifier.
    ///
    static let reuseIdentifier = EmptyStoresTableViewCell.classNameWithoutNamespaces

    /// LegendLabel: To be displayed below the ImageView.
    ///
    @IBOutlet private var legendLabel: UILabel! {
        didSet {
            legendLabel.textColor = StyleManager.wooGreyTextMin
            legendLabel.font = .subheadline
            legendLabel.text = NSLocalizedString("Unable to find WooCommerce stores connected to this account",
                                                 comment: "Displayed during the Login flow, whenever the user has no woo stores associated.")
        }
    }
}
