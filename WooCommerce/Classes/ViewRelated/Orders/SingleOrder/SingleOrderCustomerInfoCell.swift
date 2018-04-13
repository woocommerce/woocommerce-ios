import UIKit

class SingleOrderCustomerInfoCell: UITableViewCell {
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!

    static let reuseIdentifier = "SingleOrderCustomerInfoCell"

    func configureCell(title: String!, name: String!, address: String!, phone: String?, email: String?, displayExtraBorders: Bool!) {
        titleLabel.text = title
        nameLabel.text = name
        addressLabel.text = address
    }
}
