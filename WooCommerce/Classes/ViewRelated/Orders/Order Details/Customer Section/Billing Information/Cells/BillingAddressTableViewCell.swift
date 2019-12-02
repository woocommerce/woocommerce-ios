import UIKit

/// Billing Information: Renders a row that displays the billing address info's
///
final class BillingAddressTableViewCell: UITableViewCell {

    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!

    var name: String? {
        get {
            return nameLabel.text
        }
        set {
            nameLabel.text = newValue
        }
    }

    var address: String? {
        get {
            return addressLabel.text
        }
        set {
            addressLabel.text = newValue
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configureBackground()
        configureLabels()
    }
}

/// MARK: - Private Methods
///
private extension BillingAddressTableViewCell {

    func configureBackground() {
        applyDefaultBackgroundStyle()

        //Background when selected
        selectedBackgroundView = UIView()
        selectedBackgroundView?.backgroundColor = StyleManager.tableViewCellSelectionStyle
    }

    func configureLabels() {
        nameLabel.applyBodyStyle()
        addressLabel.applyBodyStyle()
    }

}

/// MARK: - Testability
extension BillingAddressTableViewCell {

    func getNameLabel() -> UILabel {
        return nameLabel
    }

    func getAddressLabel() -> UILabel {
        return addressLabel
    }
}
