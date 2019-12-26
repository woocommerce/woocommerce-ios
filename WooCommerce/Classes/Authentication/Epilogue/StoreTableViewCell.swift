import Foundation
import UIKit
import Gridicons



/// Displays a WooCommerce Store Row
///
class StoreTableViewCell: UITableViewCell {

    /// ContainerView: Checkmark
    ///
    @IBOutlet private var checkmarkContainerView: UIView!

    /// ImageView: Checkmark
    ///
    @IBOutlet private var checkmarkImageView: UIImageView!

    /// Label: Name
    ///
    @IBOutlet private var nameLabel: UILabel!

    /// Label: URL
    ///
    @IBOutlet private var urlLabel: UILabel!


    /// Store's Name
    ///
    var name: String? {
        get {
            return nameLabel?.text
        }
        set {
            nameLabel?.text = newValue
        }
    }

    /// Store's URL
    ///
    var url: String? {
        get {
            return urlLabel?.text
        }
        set {
            urlLabel?.text = newValue
        }
    }

    /// When enabled, the Checkmark ImageView will be displayed, no matter if the actual Checkmark is visible or not.
    /// This allows us to have a consistent left padding in all of our cells.
    ///
    var allowsCheckmark: Bool = false {
        didSet {
            refreshCheckmarkVisibility()
        }
    }

    /// Indicates if the Selected Checkmark should be displayed.
    ///
    var displaysCheckmark: Bool = false {
        didSet {
            guard oldValue != displaysCheckmark else {
                return
            }

            refreshCheckmarkImage()
        }
    }


    // MARK: - Overridden Methods

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureNameLabel()
        configureUrlLabel()
    }

    /// Displays (or hides) the Checkmark ContainerView, based on the `allowsCheckmark` property.
    ///
    private func refreshCheckmarkVisibility() {
        checkmarkContainerView.isHidden = !allowsCheckmark
    }

    /// Displays a Checkmark (or not) based on the `displaysCheckmark` property.
    ///
    private func refreshCheckmarkImage() {
        checkmarkImageView.image = displaysCheckmark ? .checkmarkStyledImage : nil
    }
}


private extension StoreTableViewCell {
    func configureBackground() {
        applyDefaultBackgroundStyle()
    }

    func configureNameLabel() {
        nameLabel.textColor = .text
    }

    func configureUrlLabel() {
        urlLabel.textColor = .textSubtle
    }
}
