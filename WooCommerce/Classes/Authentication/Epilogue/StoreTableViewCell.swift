import Foundation
import UIKit


/// Displays a WooCommerce Store Row
///
class StoreTableViewCell: UITableViewCell {

    /// Store's Name
    ///
    var name: String? {
        get {
            return textLabel?.text
        }
        set {
            textLabel?.text = newValue
        }
    }

    /// Store's URL
    ///
    var url: String? {
        get {
            return detailTextLabel?.text
        }
        set {
            detailTextLabel?.text =  newValue
        }
    }


    // MARK: - Overriden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        textLabel?.textColor = StyleManager.wooSecondary
        detailTextLabel?.textColor = StyleManager.wooSecondary
    }
}
