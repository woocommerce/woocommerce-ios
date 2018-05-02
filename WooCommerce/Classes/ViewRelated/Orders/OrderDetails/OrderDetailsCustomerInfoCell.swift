import UIKit

class OrderDetailsCustomerInfoCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!

    static let reuseIdentifier = "OrderDetailsCustomerInfoCell"

    func configureCell(title: String!, name: String!, address: String!) {
        titleLabel.text = title
        nameLabel.text = name
        addressLabel.text = address

        titleLabel.applyTitleStyle()
        nameLabel.applyBodyStyle()
        addressLabel.applyBodyStyle()
    }
}
