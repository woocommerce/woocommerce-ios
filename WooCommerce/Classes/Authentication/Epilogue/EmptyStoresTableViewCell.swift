import Foundation
import UIKit


/// Empty Stores: Displayed whenever there are no available WooCommerce Stores associated with the active account.
///
class EmptyStoresTableViewCell: UITableViewCell {

    /// LegendLabel: To be displayed below the ImageView.
    ///
    @IBOutlet private var legendLabel: UILabel! {
        didSet {
            legendLabel.textColor = .textSubtle
            legendLabel.font = .subheadline
            legendLabel.text = NSLocalizedString("Unable to find WooCommerce stores connected to this account",
                                                 comment: "Displayed during the Login flow, whenever the user has no woo stores associated.")
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        configureBackground()
    }
}


private extension EmptyStoresTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }
}
