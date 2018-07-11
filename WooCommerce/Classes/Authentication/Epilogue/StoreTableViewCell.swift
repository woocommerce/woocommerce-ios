import Foundation
import UIKit
import Gridicons



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

    /// Indicates if the Selected Checkmark should be displayed.
    ///
    var displaysCheckmark: Bool = false {
        didSet {
            guard oldValue != displaysCheckmark else {
                return
            }

            refreshAccessoryView()
        }
    }


    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        textLabel?.textColor = StyleManager.wooSecondary
        detailTextLabel?.textColor = StyleManager.wooSecondary
    }

    /// Displays a Checkmark (or not) based on the value of `displaysCheckmark)
    ///
    private func refreshAccessoryView() {
        accessoryView = displaysCheckmark ? UIImageView(image: .checkmarkImage) : nil
    }
}
