import UIKit

class OrderDetailsCustomerInfoCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!

    static let reuseIdentifier = "OrderDetailsCustomerInfoCell"

    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
            titleLabel.applyTitleStyle()
        }
    }

    var name: String? {
        get {
            return nameLabel.text
        }
        set {
            nameLabel.text = newValue
            nameLabel.applyBodyStyle()
        }
    }

    var address: String? {
        get {
            return addressLabel.text
        }
        set {
            addressLabel.text = newValue
            addressLabel.applyBodyStyle()
        }
    }
}

extension OrderDetailsCustomerInfoCell {
    func configure(with viewModel: ContactViewModel) {
        title = viewModel.title
        name = viewModel.fullName
        address = viewModel.formattedAddress
    }
}
